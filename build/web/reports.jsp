<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" buffer="8kb"%>
<%@ page import="java.sql.*, java.time.*, java.time.format.*, java.time.temporal.WeekFields, java.util.List, java.util.ArrayList, java.util.Map, java.util.HashMap, java.util.Locale, java.io.PrintWriter, java.io.IOException, javax.sql.DataSource, javax.naming.*" %>
<%@ page import="com.itextpdf.kernel.pdf.*, com.itextpdf.layout.*, com.itextpdf.layout.element.*, com.itextpdf.kernel.geom.*, com.itextpdf.kernel.font.*, com.itextpdf.io.font.constants.*" %>
<%@ page import="utils.DBConnection" %>
<%
// Move PDF export and data processing to the top to avoid response commitment
String errorMessage = null;
String reportType = request.getParameter("reportType");
boolean includeDetails = "on".equals(request.getParameter("includeDetails"));
LocalDate today = LocalDate.now();
DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
String username = (String) session.getAttribute("username");
String role = (String) session.getAttribute("role");

// Default date ranges
String weekStart = today.minusDays(today.getDayOfWeek().getValue() - 1).format(formatter);
String weekEnd = today.plusDays(7 - today.getDayOfWeek().getValue()).format(formatter);
String monthStart = today.withDayOfMonth(1).format(formatter);
String monthEnd = today.withDayOfMonth(today.lengthOfMonth()).format(formatter);
String overallStart = "2020-01-01";
String overallEnd = today.format(formatter);

// Report data
String startDate = "";
String endDate = "";
int pendingApps = 0, approvedApps = 0, rejectedApps = 0;
int totalSchedules = 0, totalAssigned = 0, totalCapacity = 0;
int notStarted = 0, inProgress = 0, completed = 0, failed = 0, cancelled = 0;
int totalTrainers = 0, schedulesPerTrainer = 0;
List<Map<String, String>> applications = new ArrayList<>();

// PDF support check
boolean isPdfExportSupported;
try {
    Class.forName("com.itextpdf.kernel.pdf.PdfWriter");
    isPdfExportSupported = true;
} catch (ClassNotFoundException e) {
    isPdfExportSupported = false;
    errorMessage = "PDF export is not available. Please contact the administrator to install the iText library.";
}

// Validate role
if (role == null || (!"Admin".equals(role) && !"Trainer".equals(role))) {
    session.invalidate();
    response.sendRedirect("traineeLogin.jsp");
    return;
}

// Process date inputs and fetch report data
if ("POST".equalsIgnoreCase(request.getMethod()) && reportType != null && !reportType.isEmpty()) {
    try {
        if ("weekly".equals(reportType)) {
            String week = request.getParameter("week");
            if (week == null || !week.matches("\\d{4}-W\\d{2}")) {
                throw new DateTimeParseException("Invalid week format", week, 0);
            }
            String[] weekParts = week.split("-W");
            int year = Integer.parseInt(weekParts[0]);
            int weekNumber = Integer.parseInt(weekParts[1]);
            WeekFields weekFields = WeekFields.of(Locale.getDefault());
            LocalDate weekDate = LocalDate.ofYearDay(year, 1)
                .with(weekFields.weekOfYear(), weekNumber)
                .with(weekFields.dayOfWeek(), 1);
            weekStart = weekDate.format(formatter);
            weekEnd = weekDate.plusDays(6).format(formatter);
            startDate = weekStart;
            endDate = weekEnd;
        } else if ("monthly".equals(reportType)) {
            String month = request.getParameter("month");
            if (month == null || month.isEmpty()) {
                throw new IllegalArgumentException("Month is required");
            }
            LocalDate monthDate = LocalDate.parse(month + "-01");
            monthStart = monthDate.withDayOfMonth(1).format(formatter);
            monthEnd = monthDate.withDayOfMonth(monthDate.lengthOfMonth()).format(formatter);
            startDate = monthStart;
            endDate = monthEnd;
        } else if ("overall".equals(reportType)) {
            String tempStart = request.getParameter("overallStart");
            String tempEnd = request.getParameter("overallEnd");
            if (tempStart == null || tempStart.isEmpty() || tempEnd == null || tempEnd.isEmpty()) {
                throw new IllegalArgumentException("Both start and end dates are required");
            }
            LocalDate start = LocalDate.parse(tempStart);
            LocalDate end = LocalDate.parse(tempEnd);
            if (end.isBefore(start)) {
                throw new IllegalArgumentException("End date cannot be before start date");
            }
            overallStart = tempStart;
            overallEnd = tempEnd;
            startDate = overallStart;
            endDate = overallEnd;
        }

        // Fetch report data
        try (Connection conn = DBConnection.getConnection()) {
            // Application Statistics
            String appSql = "SELECT a.status, COUNT(*) as count " +
                            "FROM bhel_training_application a " +
                            "WHERE a.applied_date BETWEEN ? AND ? ";
            if ("Trainer".equals(role)) {
                appSql += "AND a.id IN (SELECT ts.application_id FROM trainee_schedules ts " +
                          "JOIN training_schedules s ON ts.schedule_id = s.id " +
                          "WHERE s.trainer_id = (SELECT id FROM users WHERE username = ?))";
            }
            appSql += " GROUP BY a.status";
            try (PreparedStatement pstmt = conn.prepareStatement(appSql)) {
                pstmt.setDate(1, Date.valueOf(startDate));
                pstmt.setDate(2, Date.valueOf(endDate));
                if ("Trainer".equals(role)) pstmt.setString(3, username);
                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        String status = rs.getString("status");
                        int count = rs.getInt("count");
                        if ("pending".equalsIgnoreCase(status)) pendingApps = count;
                        else if ("Approved".equalsIgnoreCase(status)) approvedApps = count;
                        else if ("Rejected".equalsIgnoreCase(status)) rejectedApps = count;
                    }
                }
            }

            // Schedule Statistics
            String scheduleSql = "SELECT s.id, s.capacity, COUNT(ts.application_id) as assigned " +
                                "FROM training_schedules s " +
                                "LEFT JOIN trainee_schedules ts ON s.id = ts.schedule_id " +
                                "WHERE s.start_date <= ? AND s.end_date >= ? ";
            if ("Trainer".equals(role)) scheduleSql += "AND s.trainer_id = (SELECT id FROM users WHERE username = ?)";
            scheduleSql += " GROUP BY s.id, s.capacity";
            try (PreparedStatement pstmt = conn.prepareStatement(scheduleSql)) {
                pstmt.setDate(1, Date.valueOf(endDate));
                pstmt.setDate(2, Date.valueOf(startDate));
                if ("Trainer".equals(role)) pstmt.setString(3, username);
                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        totalSchedules++;
                        totalAssigned += rs.getInt("assigned");
                        totalCapacity += rs.getInt("capacity");
                    }
                }
            }

            // Trainee Progress
            String progressSql = "SELECT ts.progress, COUNT(*) as count " +
                                "FROM trainee_schedules ts " +
                                "JOIN training_schedules s ON ts.schedule_id = s.id " +
                                "WHERE s.start_date <= ? AND s.end_date >= ? ";
            if ("Trainer".equals(role)) progressSql += "AND s.trainer_id = (SELECT id FROM users WHERE username = ?)";
            progressSql += " GROUP BY ts.progress";
            try (PreparedStatement pstmt = conn.prepareStatement(progressSql)) {
                pstmt.setDate(1, Date.valueOf(endDate));
                pstmt.setDate(2, Date.valueOf(startDate));
                if ("Trainer".equals(role)) pstmt.setString(3, username);
                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        String progress = rs.getString("progress");
                        int count = rs.getInt("count");
                        if ("Not Started".equalsIgnoreCase(progress)) notStarted = count;
                        else if ("In Progress".equalsIgnoreCase(progress)) inProgress = count;
                        else if ("Completed".equalsIgnoreCase(progress)) completed = count;
                        else if ("Failed".equalsIgnoreCase(progress)) failed = count;
                        else if ("Cancelled".equalsIgnoreCase(progress)) cancelled = count;
                    }
                }
            }

            // Trainer Involvement (Admin-only)
            if ("Admin".equals(role)) {
                try (PreparedStatement pstmt = conn.prepareStatement(
                        "SELECT COUNT(DISTINCT trainer_id) as trainer_count, COUNT(*) as schedule_count " +
                        "FROM training_schedules WHERE start_date <= ? AND end_date >= ?")) {
                    pstmt.setDate(1, Date.valueOf(endDate));
                    pstmt.setDate(2, Date.valueOf(startDate));
                    try (ResultSet rs = pstmt.executeQuery()) {
                        if (rs.next()) {
                            totalTrainers = rs.getInt("trainer_count");
                            schedulesPerTrainer = totalTrainers > 0 ? rs.getInt("schedule_count") / totalTrainers : 0;
                        }
                    }
                }
            }

            // Detailed Applications (if requested)
            if (includeDetails) {
                String detailSql = "SELECT a.id, a.applicant_name, a.training_program, a.status, a.email, a.training_fee, a.payment_status, ts.progress, s.start_date, s.end_date " +
                                  "FROM bhel_training_application a " +
                                  "LEFT JOIN trainee_schedules ts ON a.id = ts.application_id " +
                                  "LEFT JOIN training_schedules s ON ts.schedule_id = s.id " +
                                  "WHERE a.applied_date BETWEEN ? AND ? ";
                if ("Trainer".equals(role)) {
                    detailSql += "AND (s.trainer_id = (SELECT id FROM users WHERE username = ?) OR s.trainer_id IS NULL)";
                }
                try (PreparedStatement pstmt = conn.prepareStatement(detailSql)) {
                    pstmt.setDate(1, Date.valueOf(startDate));
                    pstmt.setDate(2, Date.valueOf(endDate));
                    if ("Trainer".equals(role)) pstmt.setString(3, username);
                    try (ResultSet rs = pstmt.executeQuery()) {
                        while (rs.next()) {
                            Map<String, String> app = new HashMap<>();
                            app.put("id", String.valueOf(rs.getInt("id")));
                            app.put("applicant_name", rs.getString("applicant_name") != null ? rs.getString("applicant_name") : "N/A");
                            app.put("training_program", rs.getString("training_program") != null ? rs.getString("training_program") : "N/A");
                            app.put("status", rs.getString("status") != null ? rs.getString("status") : "N/A");
                            app.put("email", rs.getString("email") != null ? rs.getString("email") : "N/A");
                            app.put("training_fee", rs.getString("training_fee") != null ? rs.getString("training_fee") : "N/A");
                            app.put("payment_status", rs.getString("payment_status") != null ? rs.getString("payment_status") : "N/A");
                            app.put("progress", rs.getString("progress") != null ? rs.getString("progress") : "N/A");
                            app.put("start_date", rs.getDate("start_date") != null ? rs.getDate("start_date").toString() : "N/A");
                            app.put("end_date", rs.getDate("end_date") != null ? rs.getDate("end_date").toString() : "N/A");
                            applications.add(app);
                        }
                    }
                }
            }
        }
    } catch (SQLException e) {
        errorMessage = "Error: Database query failed: " + e.getMessage() + ". Please verify database connection and schema.";
        e.printStackTrace();
    } catch (NamingException e) {
        errorMessage = "Error: JNDI lookup failed: " + e.getMessage() + ". Ensure 'jdbc/trainingDB' is defined in META-INF/context.xml and Tomcat is configured correctly.";
        e.printStackTrace();
    } catch (Exception e) {
        errorMessage = "Error: Invalid date input. Please use correct formats (Week: YYYY-WWW, Month: YYYY-MM, Dates: YYYY-MM-DD).";
        e.printStackTrace();
    }
}

// Handle PDF export
if ("POST".equalsIgnoreCase(request.getMethod()) && "pdf".equals(request.getParameter("export")) && isPdfExportSupported && errorMessage == null) {
    try {
        response.reset();
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + reportType + "_report.pdf\"");
        PdfWriter writer = new PdfWriter(response.getOutputStream());
        PdfDocument pdf = new PdfDocument(writer);
        Document document = new Document(pdf, PageSize.A4);
        document.setMargins(20, 20, 20, 20);

        document.add(new Paragraph("BHEL HRDC - " + reportType.substring(0, 1).toUpperCase() + reportType.substring(1) + " Report")
            .setFontSize(16).setBold());
        document.add(new Paragraph("Period: " + startDate + " to " + endDate).setFontSize(12));

        float[] columnWidths = {200, 300};
        Table table = new Table(columnWidths).setWidth(PageSize.A4.getWidth() - 40);
        table.addHeaderCell(new Cell().add(new Paragraph("Metric").setBold()));
        table.addHeaderCell(new Cell().add(new Paragraph("Value").setBold()));
        table.addCell(new Cell().add(new Paragraph("Total Applications")));
        table.addCell(new Cell().add(new Paragraph((pendingApps + approvedApps + rejectedApps) + " (Pending: " + pendingApps + ", Approved: " + approvedApps + ", Rejected: " + rejectedApps + ")")));
        table.addCell(new Cell().add(new Paragraph("Active Schedules")));
        table.addCell(new Cell().add(new Paragraph(String.valueOf(totalSchedules))));
        table.addCell(new Cell().add(new Paragraph("Trainees Assigned")));
        table.addCell(new Cell().add(new Paragraph(totalAssigned + "/" + totalCapacity)));
        table.addCell(new Cell().add(new Paragraph("Trainee Progress")));
        table.addCell(new Cell().add(new Paragraph("Not Started: " + notStarted + ", In Progress: " + inProgress + ", Completed: " + completed + ", Failed: " + failed + ", Cancelled: " + cancelled)));
        if ("Admin".equals(role)) {
            table.addCell(new Cell().add(new Paragraph("Trainer Involvement")));
            table.addCell(new Cell().add(new Paragraph("Total Trainers: " + totalTrainers + ", Avg. Schedules per Trainer: " + schedulesPerTrainer)));
        }
        document.add(table);

        if (includeDetails && !applications.isEmpty()) {
            document.add(new Paragraph("Individual Applications").setFontSize(14).setBold().setMarginTop(20));
            float[] detailWidths = {40, 60, 80, 40, 80, 40, 40, 40, 60, 60};
            Table detailTable = new Table(detailWidths).setWidth(PageSize.A4.getWidth() - 40);
            detailTable.addHeaderCell(new Cell().add(new Paragraph("ID").setBold()));
            detailTable.addHeaderCell(new Cell().add(new Paragraph("Applicant").setBold()));
            detailTable.addHeaderCell(new Cell().add(new Paragraph("Training").setBold()));
            detailTable.addHeaderCell(new Cell().add(new Paragraph("Status").setBold()));
            detailTable.addHeaderCell(new Cell().add(new Paragraph("Email").setBold()));
            detailTable.addHeaderCell(new Cell().add(new Paragraph("Fee").setBold()));
            detailTable.addHeaderCell(new Cell().add(new Paragraph("Payment").setBold()));
            detailTable.addHeaderCell(new Cell().add(new Paragraph("Progress").setBold()));
            detailTable.addHeaderCell(new Cell().add(new Paragraph("Start Date").setBold()));
            detailTable.addHeaderCell(new Cell().add(new Paragraph("End Date").setBold()));
            for (Map<String, String> app : applications) {
                detailTable.addCell(new Cell().add(new Paragraph(app.get("id") != null ? app.get("id") : "N/A")));
                detailTable.addCell(new Cell().add(new Paragraph(app.get("applicant_name") != null ? app.get("applicant_name") : "N/A")));
                detailTable.addCell(new Cell().add(new Paragraph(app.get("training_program") != null ? app.get("training_program") : "N/A")));
                detailTable.addCell(new Cell().add(new Paragraph(app.get("status") != null ? app.get("status") : "N/A")));
                detailTable.addCell(new Cell().add(new Paragraph(app.get("email") != null ? app.get("email") : "N/A")));
                detailTable.addCell(new Cell().add(new Paragraph(app.get("training_fee") != null ? app.get("training_fee") : "N/A")));
                detailTable.addCell(new Cell().add(new Paragraph(app.get("payment_status") != null ? app.get("payment_status") : "N/A")));
                detailTable.addCell(new Cell().add(new Paragraph(app.get("progress") != null ? app.get("progress") : "N/A")));
                detailTable.addCell(new Cell().add(new Paragraph(app.get("start_date") != null ? app.get("start_date") : "N/A")));
                detailTable.addCell(new Cell().add(new Paragraph(app.get("end_date") != null ? app.get("end_date") : "N/A")));
            }
            document.add(detailTable);
        }

        document.add(new Paragraph("BHEL HRDC | Bharat Heavy Electricals Limited")
            .setFontSize(10).setMarginTop(20));
        document.add(new Paragraph("© 2025 BHEL. All rights reserved.").setFontSize(10));
        document.close();
        return; // Exit JSP to prevent HTML rendering
    } catch (IOException e) {
        errorMessage = "Error: Failed to generate PDF: " + e.getMessage() + ". Please check server logs.";
        e.printStackTrace();
    } catch (Exception e) {
        errorMessage = "Error: Unexpected error during PDF export: " + e.getMessage() + ". Please contact the administrator.";
        e.printStackTrace();
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reports - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    
    <script>
        // Track touched fields
        const touchedFields = new Set();

        // Validation functions
        function validateWeek(value) {
            const regex = /^\d{4}-W\d{2}$/;
            return regex.test(value);
        }

        function validateMonth(value) {
            const regex = /^\d{4}-\d{2}$/;
            return regex.test(value);
        }

        function validateDate(value) {
            const regex = /^\d{4}-\d{2}-\d{2}$/;
            return regex.test(value) && !isNaN(new Date(value));
        }

        function validateReportType(value) {
            return ["weekly", "monthly", "overall"].includes(value);
        }

        function validateDateRange(startDate, endDate) {
            if (!startDate || !endDate) return false;
            const start = new Date(startDate);
            const end = new Date(endDate);
            return start <= end;
        }

        // Show/hide error message
        function toggleError(inputElement, message, isValid) {
            let errorElement = inputElement.nextElementSibling;
            if (!errorElement || !errorElement.classList.contains('error-message')) {
                errorElement = document.createElement('span');
                errorElement.className = 'error-message';
                inputElement.parentNode.insertBefore(errorElement, inputElement.nextSibling);
            }
            errorElement.innerText = isValid ? '' : message;
            errorElement.classList.toggle('active', !isValid);
        }

        // Validate input fields
        function validateInput(inputElement, forceShowError = false) {
            const name = inputElement.name;
            const value = inputElement.value.trim();
            const isTouched = touchedFields.has(inputElement) || forceShowError;

            if (!isTouched && value === '') {
                toggleError(inputElement, '', true);
                return;
            }

            let isValid = false;
            let errorMessage = '';

            switch (name) {
                case 'reportType':
                    isValid = validateReportType(value);
                    errorMessage = 'Please select a valid report type.';
                    break;
                case 'week':
                    isValid = validateWeek(value);
                    errorMessage = 'Please enter a valid week (YYYY-WWW).';
                    break;
                case 'month':
                    isValid = validateMonth(value);
                    errorMessage = 'Please enter a valid month (YYYY-MM).';
                    break;
                case 'overallStart':
                case 'overallEnd':
                    isValid = validateDate(value);
                    errorMessage = 'Please enter a valid date (YYYY-MM-DD).';
                    if (isValid && name === 'overallEnd') {
                        const startDate = document.querySelector('input[name="overallStart"]').value;
                        isValid = validateDateRange(startDate, value);
                        errorMessage = isValid ? errorMessage : 'End date must be after start date.';
                    }
                    break;
            }

            toggleError(inputElement, errorMessage, isValid);
        }

        // Initialize validation
        function initializeValidation() {
            const inputs = document.querySelectorAll('input, select');
            inputs.forEach(input => {
                input.addEventListener('input', () => {
                    touchedFields.add(input);
                    validateInput(input);
                });
                input.addEventListener('change', () => {
                    touchedFields.add(input);
                    validateInput(input, true);
                });
                input.addEventListener('blur', () => {
                    touchedFields.add(input);
                    validateInput(input, true);
                });
            });

            // Validate form on submit
            
        }

        // Toggle date fields
        function toggleDateFields() {
            const reportType = document.getElementById("reportType").value;
            document.getElementById("weekFields").style.display = reportType === "weekly" ? "block" : "none";
            document.getElementById("monthFields").style.display = reportType === "monthly" ? "block" : "none";
            document.getElementById("overallFields").style.display = reportType === "overall" ? "block" : "none";
            // Revalidate visible fields
            const inputs = document.querySelectorAll('#weekFields input, #monthFields input, #overallFields input');
            inputs.forEach(input => validateInput(input, touchedFields.has(input)));
        }

        window.onload = function() {
            toggleDateFields();
            initializeValidation();
        };
    </script>
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="container">
        <div class="hero">
            <div class="hero-content">
                <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
                <h1>Reports - BHEL HRDC</h1>
            </div>
        </div>
        <div class="content">
            <h2>Training Application Reports</h2>
            <% if (errorMessage != null) { %>
            <div class="alert alert-error">
                <p><%= errorMessage %></p>
            </div>
            <% } %>
            <form action="reports.jsp" method="post">
                <div class="form-group">
                    <label for="reportType">Report Type:</label>
                    <select id="reportType" name="reportType" onchange="toggleDateFields()" required>
                        <option value="">Select Report Type</option>
                        <option value="weekly" <%= "weekly".equals(reportType) ? "selected" : "" %>>Weekly</option>
                        <option value="monthly" <%= "monthly".equals(reportType) ? "selected" : "" %>>Monthly</option>
                        <option value="overall" <%= "overall".equals(reportType) ? "selected" : "" %>>Overall</option>
                    </select>
                    <span class="error-message"></span>
                </div>
                <div id="weekFields" style="display: <%= "weekly".equals(reportType) ? "block" : "none" %>;">
                    <div class="form-group">
                        <label for="week">Select Week:</label>
                        <input type="week" id="week" name="week" value="<%= request.getParameter("week") != null ? request.getParameter("week") : today.format(DateTimeFormatter.ofPattern("yyyy-'W'ww")) %>" required>
                        <span class="error-message"></span>
                    </div>
                </div>
                <div id="monthFields" style="display: <%= "monthly".equals(reportType) ? "block" : "none" %>;">
                    <div class="form-group">
                        <label for="month">Select Month:</label>
                        <input type="month" id="month" name="month" value="<%= request.getParameter("month") != null ? request.getParameter("month") : today.format(DateTimeFormatter.ofPattern("yyyy-MM")) %>" required>
                        <span class="error-message"></span>
                    </div>
                </div>
                <div id="overallFields" style="display: <%= "overall".equals(reportType) ? "block" : "none" %>;" class="form-group inline">
                    <div>
                        <label for="overallStart">Start Date:</label>
                        <input type="date" id="overallStart" name="overallStart" value="<%= request.getParameter("overallStart") != null ? request.getParameter("overallStart") : overallStart %>" required>
                        <span class="error-message"></span>
                    </div>
                    <div>
                        <label for="overallEnd">End Date:</label>
                        <input type="date" id="overallEnd" name="overallEnd" value="<%= request.getParameter("overallEnd") != null ? request.getParameter("overallEnd") : overallEnd %>" required>
                        <span class="error-message"></span>
                    </div>
                </div>
                <div class="checkbox-group">
                    <input type="checkbox" id="includeDetailsCheckbox" name="includeDetails" <%= includeDetails ? "checked" : "" %>>
                    <label for="includeDetailsCheckbox">Include Individual Applications</label>
                </div>
                <button type="submit" class="btn cta-btn">Generate Report</button>
            </form>
            <br>
            <% if (reportType != null && !reportType.isEmpty() && errorMessage == null) { %>
            <h3><%= reportType.substring(0, 1).toUpperCase() + reportType.substring(1) %> Report</h3>
            <p>Period: <%= startDate %> to <%= endDate %></p>
            <table class="dashboard-table">
                <thead>
                    <tr>
                        <th>Metric</th>
                        <th>Value</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Total Applications</td>
                        <td><%= pendingApps + approvedApps + rejectedApps %> (Pending: <%= pendingApps %>, Approved: <%= approvedApps %>, Rejected: <%= rejectedApps %>)</td>
                    </tr>
                    <tr>
                        <td>Active Schedules</td>
                        <td><%= totalSchedules %></td>
                    </tr>
                    <tr>
                        <td>Trainees Assigned</td>
                        <td><%= totalAssigned %>/<%= totalCapacity %></td>
                    </tr>
                    <tr>
                        <td>Trainee Progress</td>
                        <td>Not Started: <%= notStarted %>, In Progress: <%= inProgress %>, Completed: <%= completed %>, Failed: <%= failed %>, Cancelled: <%= cancelled %></td>
                    </tr>
                    <% if ("Admin".equals(role)) { %>
                    <tr>
                        <td>Trainer Involvement</td>
                        <td>Total Trainers: <%= totalTrainers %>, Avg. Schedules per Trainer: <%= schedulesPerTrainer %></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
            <% if (includeDetails && !applications.isEmpty()) { %>
            <h3>Individual Applications</h3>
            <table class="dashboard-table">
                <thead>
                    <tr>
                        <th>Application ID</th>
                        <th>Applicant Name</th>
                        <th>Training Program</th>
                        <th>Status</th>
                        <th>Training Fee</th>
                        <th>Payment Status</th>
                        <th>Progress</th>
                        <th>Start Date</th>
                        <th>End Date</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Map<String, String> app : applications) { %>
                    <tr>
                        <td><%= app.get("id") %></td>
                        <td><%= app.get("applicant_name") %></td>
                        <td><%= app.get("training_program") %></td>
                        <td><%= app.get("status") %></td>
                        <td><%= app.get("training_fee") %></td>
                        <td><%= app.get("payment_status") %></td>
                        <td><%= app.get("progress") %></td>
                        <td><%= app.get("start_date") %></td>
                        <td><%= app.get("end_date") %></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
            <% } else if (includeDetails) { %>
            <div class="alert alert-info">
                <p>No applications found for the selected period.</p>
            </div>
            <% } %>
            <form action="reports.jsp" method="post" style="margin-top: 20px;">
                <input type="hidden" name="reportType" value="<%= reportType %>">
                <input type="hidden" name="week" value="<%= request.getParameter("week") %>">
                <input type="hidden" name="month" value="<%= request.getParameter("month") %>">
                <input type="hidden" name="overallStart" value="<%= overallStart %>">
                <input type="hidden" name="overallEnd" value="<%= overallEnd %>">
                <input type="hidden" name="includeDetails" value="<%= includeDetails ? "on" : "" %>">
                <button type="submit" name="export" value="pdf" class="btn cta-btn" <%= isPdfExportSupported ? "" : "disabled title='PDF export requires iText library'" %>>Export as PDF</button>
            </form>
            <br>
            <%if ( ("Admin".equals(role))) {%>
                <a href="adminDashboard.jsp" class="btn secondary-cta-btn">Back to Dashboard</a>
            <%}else{%>
                <a href="trainerDashboard.jsp" class="btn secondary-cta-btn">Back to Dashboard</a>
            <%}%>
            
            <% } %>
        </div>
    </div>
    <jsp:include page="footer.jsp" />
</body>
</html>