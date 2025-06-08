<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="utils.DBConnection, java.sql.*, java.time.LocalDate, java.time.format.DateTimeFormatter, java.util.Arrays" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Schedules - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    <style>
        .error-message {
            color: #9b2c2c;
            background-color: #fed7d7;
            border: 1px solid #f6ad55;
            padding: 8px 12px;
            margin-top: 5px;
            border-radius: 5px;
            font-size: 0.9em;
            display: none;
        }
        .error-message.active {
            display: block;
        }
        .reset-date-btn {
            background: linear-gradient(135deg, #4a5568, #cbd5e0);
            display: none;
        }
        .reset-date-btn.visible {
            display: inline-block;
        }
        
    </style>
    <script>
        const touchedFields = new Set();
        let calculatedEndDate = '';

        function validateDropdown(value, name) {
            if (name === "training_period") {
                const validValues = ["1 month", "2 months", "3 months", "4 months", "5 months", "6 months"];
                return validValues.includes(value);
            }
            return value !== "" && value !== "Select Training Type" && value !== "Select Training Period";
        }

        function validateDate(value, isStartDate = false) {
            const date = new Date(value);
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            return date instanceof Date && !isNaN(date) && (!isStartDate || date >= today);
        }

        function validateEndDate(startDate, endDate) {
            const start = new Date(startDate);
            const end = new Date(endDate);
            return end >= start;
        }

        function validateCapacity(value) {
            return value > 0;
        }

        function toggleError(inputElement, message, isValid) {
            let errorElement = inputElement.nextElementSibling;
            if (!errorElement || !errorElement.classList.contains('error-message')) {
                errorElement = document.createElement('span');
                errorElement.className = 'error-message';
                inputElement.parentNode.insertBefore(errorElement, inputElement.nextSibling);
            }
            errorElement.innerText = message;
            errorElement.classList.toggle('active', !isValid && message !== '');
        }

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
                case 'training_type':
                case 'trainer_id':
                    isValid = validateDropdown(value, name);
                    errorMessage = 'Please select an option.';
                    break;
                case 'training_period':
                    isValid = validateDropdown(value, name) || document.getElementById("training_type").value === "Diploma (6 Months)";
                    errorMessage = 'Please select a valid training period.';
                    break;
                case 'start_date':
                    isValid = validateDate(value, true);
                    errorMessage = 'Must be a valid date on or after today.';
                    break;
                case 'end_date':
                    const startDate = document.forms["scheduleForm"]["start_date"].value;
                    isValid = validateDate(value) && validateEndDate(startDate, value);
                    errorMessage = 'Must be a valid date on or after the start date.';
                    break;
                case 'capacity':
                    isValid = validateCapacity(value);
                    errorMessage = 'Must be a positive number.';
                    break;
            }

            toggleError(inputElement, errorMessage, isValid);
        }

        function initializeValidation() {
            const inputs = document.querySelectorAll('input:not([type="hidden"])');
            const selects = document.querySelectorAll('select');
            inputs.forEach(input => {
                input.addEventListener('input', () => {
                    touchedFields.add(input);
                    validateInput(input);
                    if (input.name === 'start_date') {
                        updateEndDate();
                    } else if (input.name === 'end_date') {
                        toggleResetDateButton();
                    }
                });
                input.addEventListener('blur', () => {
                    touchedFields.add(input);
                    validateInput(input, true);
                });
            });
            selects.forEach(select => {
                select.addEventListener('change', () => {
                    touchedFields.add(select);
                    validateInput(select, true);
                    if (select.name === 'training_type' || select.name === 'training_period') {
                        updateTrainingPeriod();
                        updateEndDate();
                    }
                });
            });

            const resetDateBtn = document.getElementById('reset-date-btn');
            if (resetDateBtn) {
                resetDateBtn.addEventListener('click', () => {
                    const endDateInput = document.forms["scheduleForm"]["end_date"];
                    endDateInput.value = calculatedEndDate;
                    validateInput(endDateInput, true);
                    toggleResetDateButton();
                });
            }
        }

        function updateTrainingPeriod() {
            const trainingType = document.getElementById("training_type").value;
            const periodDiv = document.getElementById("training_period_div");
            const periodSelect = document.getElementById("training_period");
            const currentValue = periodSelect.value;

            if (trainingType === "Diploma (6 Months)") {
                periodDiv.style.display = "none";
                periodSelect.value = "6 months";
                periodSelect.disabled = true;
            } else if (["Graduate (3 Years)", "Graduate (4 Years)", "Postgraduate"].includes(trainingType)) {
                periodDiv.style.display = "block";
                periodSelect.disabled = false;
                periodSelect.innerHTML = "";
                const options = ["", "1 month", "2 months", "3 months", "4 months", "5 months", "6 months"];
                options.forEach(optionValue => {
                    const option = document.createElement("option");
                    option.value = optionValue;
                    option.text = optionValue || "Select Training Period";
                    periodSelect.appendChild(option);
                });
                periodSelect.value = currentValue && options.includes(currentValue) ? currentValue : "";
            } else {
                periodDiv.style.display = "none";
                periodSelect.value = "";
                periodSelect.disabled = true;
            }
            validateInput(periodSelect, touchedFields.has(periodSelect));
            updateEndDate();
        }

        function updateEndDate() {
            const startDateInput = document.forms["scheduleForm"]["start_date"];
            const trainingPeriod = document.forms["scheduleForm"]["training_period"].value;
            const endDateInput = document.forms["scheduleForm"]["end_date"];
            const trainingType = document.getElementById("training_type").value;

            if (startDateInput.value && (trainingPeriod || trainingType === "Diploma (6 Months)") && validateDate(startDateInput.value, true)) {
                const startDate = new Date(startDateInput.value);
                const months = trainingType === "Diploma (6 Months)" ? 6 : parseInt(trainingPeriod) || 0;
                const endDate = new Date(startDate);
                endDate.setMonth(startDate.getMonth() + months);
                endDate.setDate(endDate.getDate() - 1);
                calculatedEndDate = endDate.toISOString().split('T')[0];
                endDateInput.value = calculatedEndDate;
            } else {
                calculatedEndDate = '';
                if (!endDateInput.value) {
                    endDateInput.value = '';
                }
            }
            validateInput(endDateInput, touchedFields.has(endDateInput));
            toggleResetDateButton();
        }

        function toggleResetDateButton() {
            const endDateInput = document.forms["scheduleForm"]["end_date"];
            const resetDateBtn = document.getElementById('reset-date-btn');
            if (resetDateBtn) {
                resetDateBtn.classList.toggle('visible', calculatedEndDate !== '' && endDateInput.value !== calculatedEndDate);
            }
        }

        function validateForm() {
            const inputs = document.querySelectorAll('input:not([type="hidden"]), select:not([name="training_period"])');
            let isValid = true;
            inputs.forEach(input => {
                validateInput(input, true);
                if (input.nextElementSibling.classList.contains('active')) {
                    isValid = false;
                }
            });
            const trainingType = document.getElementById("training_type").value;
            if (trainingType !== "Diploma (6 Months)") {
                const periodSelect = document.getElementById("training_period");
                validateInput(periodSelect, true);
                if (periodSelect.nextElementSibling.classList.contains('active')) {
                    isValid = false;
                }
            }
            const submitButton = document.querySelector('button[type="submit"]');
            submitButton.disabled = !isValid;
            submitButton.innerText = isValid ? 'Submitting...' : 'Create Schedule';
            return isValid;
        }

        window.onload = function() {
            initializeValidation();
            updateTrainingPeriod();
            updateEndDate();
        };
    </script>
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="container">
        <div class="hero">
            <div class="hero-content">
                <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
                <h1>Manage Training Schedules - BHEL HRDC</h1>
            </div>
        </div>
        <%
            String username = (String) session.getAttribute("username");
            String role = (String) session.getAttribute("role");
            if (username == null || role == null || !role.equals("Admin")) {
                response.sendRedirect("traineeLogin.jsp?error=Unauthorized access");
                return;
            }

            String successMessage = (String) session.getAttribute("successMessage");
            String errorMessage = null;
            if (successMessage != null) {
                session.removeAttribute("successMessage"); // Clear the session attribute
            }
            Connection conn = null;
            try {
                conn = DBConnection.getConnection();
                LocalDate today = LocalDate.now();
                DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");

                if ("POST".equalsIgnoreCase(request.getMethod()) && request.getParameter("action") == null) {
                    String trainingType = request.getParameter("training_type");
                    String trainingPeriod = request.getParameter("training_period");
                    String startDate = request.getParameter("start_date");
                    String endDate = request.getParameter("end_date");
                    String capacity = request.getParameter("capacity");
                    String trainerId = request.getParameter("trainer_id");

                    String[] validTrainingTypes = {"Diploma (6 Months)", "Graduate (3 Years)", "Graduate (4 Years)", "Postgraduate"};
                    String[] validTrainingPeriods = {"1 month", "2 months", "3 months", "4 months", "5 months", "6 months"};

                    if (trainingType == null || startDate == null || endDate == null || capacity == null || trainerId == null) {
                        errorMessage = "Required fields are missing.";
                    } else if (!Arrays.asList(validTrainingTypes).contains(trainingType)) {
                        errorMessage = "Invalid training type.";
                    } else if (!trainingType.equals("Diploma (6 Months)") && (trainingPeriod == null || !Arrays.asList(validTrainingPeriods).contains(trainingPeriod))) {
                        errorMessage = "Invalid or missing training period.";
                    } else {
                        LocalDate start = LocalDate.parse(startDate);
                        LocalDate end = LocalDate.parse(endDate);
                        int capacityValue = Integer.parseInt(capacity);
                        if (start.isBefore(today)) {
                            errorMessage = "Start date must be on or after today.";
                        } else if (end.isBefore(start)) {
                            errorMessage = "End date must be on or after the start date.";
                        } else if (capacityValue <= 0) {
                            errorMessage = "Capacity must be a positive number.";
                        } else {
                            try (PreparedStatement createStmt = conn.prepareStatement(
                                    "INSERT INTO training_schedules (training_type, training_period, start_date, end_date, capacity, trainer_id) VALUES (?, ?, ?, ?, ?, ?)")) {
                                createStmt.setString(1, trainingType);
                                createStmt.setString(2, trainingType.equals("Diploma (6 Months)") ? "6 months" : trainingPeriod);
                                createStmt.setString(3, startDate);
                                createStmt.setString(4, endDate);
                                createStmt.setInt(5, capacityValue);
                                createStmt.setInt(6, Integer.parseInt(trainerId));
                                createStmt.executeUpdate();
                                successMessage = "Schedule created successfully!";
                            }
                        }
                    }
                }

                if ("POST".equalsIgnoreCase(request.getMethod()) && "delete".equals(request.getParameter("action"))) {
                    int scheduleId = Integer.parseInt(request.getParameter("scheduleId"));
                    try (PreparedStatement checkStmt = conn.prepareStatement("SELECT COUNT(*) FROM trainee_schedules WHERE schedule_id = ?")) {
                        checkStmt.setInt(1, scheduleId);
                        try (ResultSet checkRs = checkStmt.executeQuery()) {
                            checkRs.next();
                            int assignedTrainees = checkRs.getInt(1);
                            if (assignedTrainees > 0) {
                                errorMessage = "Cannot delete schedule: " + assignedTrainees + " trainee(s) are assigned.";
                            } else {
                                try (PreparedStatement deleteStmt = conn.prepareStatement("DELETE FROM training_schedules WHERE id = ?")) {
                                    deleteStmt.setInt(1, scheduleId);
                                    deleteStmt.executeUpdate();
                                    successMessage = "Schedule deleted successfully!";
                                }
                            }
                        }
                    }
                }

                if (successMessage != null) {
        %>
        <div class="alert alert-success">
            <p><%= successMessage %></p>
        </div>
        <%
                } else if (errorMessage != null) {
        %>
        <div class="alert alert-error">
            <p><%= errorMessage %></p>
        </div>
        <%
                }
        %>
        <div class="content">
            <h2>Create New Schedule</h2>
            <form name="scheduleForm" action="manageSchedules.jsp" method="post" onsubmit="return validateForm()">
                <div class="form-group">
                    <label>Training Type:</label>
                    <select id="training_type" name="training_type" required>
                        <option value="">Select Training Type</option>
                        <option value="Diploma (6 Months)">Diploma (6 Months)</option>
                        <option value="Graduate (3 Years)">Graduate (3 Years)</option>
                        <option value="Graduate (4 Years)">Graduate (4 Years)</option>
                        <option value="Postgraduate">Postgraduate</option>
                    </select>
                    <span class="error-message"></span>
                </div>
                <div class="form-group" id="training_period_div" style="display: none;">
                    <label>Training Period:</label>
                    <select id="training_period" name="training_period">
                        <option value="">Select Training Period</option>
                    </select>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>Start Date:</label>
                    <input type="date" name="start_date" required>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>End Date:</label>
                    <input type="date" name="end_date" required>
                    <br>
                    <br>
                    <button type="button" id="reset-date-btn" class="btn reset-date-btn">Reset Date</button>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>Capacity:</label>
                    <input type="number" name="capacity" min="1" required>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>Assign Trainer:</label>
                    <select name="trainer_id" required>
                        <option value="">Select Trainer</option>
                        <%
                            try (PreparedStatement trainerStmt = conn.prepareStatement("SELECT id, username FROM users WHERE role = 'Trainer'");
                                 ResultSet trainerRs = trainerStmt.executeQuery()) {
                                while (trainerRs.next()) {
                                    int trainerId = trainerRs.getInt("id");
                                    String trainerUsername = trainerRs.getString("username");
                        %>
                        <option value="<%= trainerId %>"><%= trainerUsername %></option>
                        <%
                                }
                            }
                        %>
                    </select>
                    <span class="error-message"></span>
                </div>
                <button type="submit" class="btn cta-btn">Create Schedule</button>
            </form>
            <h2>Active and Upcoming Schedules</h2>
            <div class="table-container">
                <table class="dashboard-table">
                    <thead>
                        <tr>
                            <th data-label="Schedule ID">Schedule ID</th>
                            <th data-label="Training Type">Training Type</th>
                            <th data-label="Period">Period</th>
                            <th data-label="Start Date">Start Date</th>
                            <th data-label="End Date">End Date</th>
                            <th data-label="Capacity">Capacity</th>
                            <th data-label="Trainer">Trainer</th>
                            <th data-label="Actions">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try (PreparedStatement scheduleStmt = conn.prepareStatement(
                                    "SELECT s.id, s.training_type, s.training_period, s.start_date, s.end_date, s.capacity, u.username as trainer, " +
                                    "COUNT(ts.schedule_id) as assigned_trainees " +
                                    "FROM training_schedules s " +
                                    "JOIN users u ON s.trainer_id = u.id " +
                                    "LEFT JOIN trainee_schedules ts ON ts.schedule_id = s.id " +
                                    "WHERE s.end_date >= CURDATE() " +
                                    "GROUP BY s.id, s.training_type, s.training_period, s.start_date, s.end_date, s.capacity, u.username");
                                 ResultSet scheduleRs = scheduleStmt.executeQuery()) {
                                boolean hasSchedules = false;
                                while (scheduleRs.next()) {
                                    hasSchedules = true;
                                    int scheduleId = scheduleRs.getInt("id");
                                    String trainingType = scheduleRs.getString("training_type");
                                    String trainingPeriod = scheduleRs.getString("training_period");
                                    String startDate = scheduleRs.getString("start_date");
                                    String endDate = scheduleRs.getString("end_date");
                                    int capacity = scheduleRs.getInt("capacity");
                                    int assignedTrainees = scheduleRs.getInt("assigned_trainees");
                                    String trainer = scheduleRs.getString("trainer");
                        %>
                        <tr>
                            <td data-label="Schedule ID"><%= scheduleId %></td>
                            <td data-label="Training Type"><%= trainingType %></td>
                            <td data-label="Period"><%= trainingPeriod %></td>
                            <td data-label="Start Date"><%= startDate %></td>
                            <td data-label="End Date"><%= endDate %></td>
                            <td data-label="Capacity"><%= assignedTrainees %>/<%= capacity %></td>
                            <td data-label="Trainer"><%= trainer %></td>
                            <td data-label="Actions">
                                <a href="editSchedule.jsp?scheduleId=<%= scheduleId %>" class="btn cta-btn">Edit</a>
                                <form action="manageSchedules.jsp" method="post" style="display:inline;">
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="scheduleId" value="<%= scheduleId %>">
                                    <button type="submit" class="btn secondary-cta-btn" <%= assignedTrainees > 0 ? "disabled" : "" %>>Delete</button>
                                </form>
                            </td>
                        </tr>
                        <%
                                }
                                if (!hasSchedules) {
                        %>
                        <tr>
                            <td colspan="8">No active or upcoming schedules found.</td>
                        </tr>
                        <%
                                }
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>
        <%
            } catch (SQLException e) {
        %>
        <div class="alert alert-error">
            <p>Error: Unable to manage schedules. Please try again later.</p>
        </div>
        <%
            } finally {
                if (conn != null) {
                    try {
                        conn.close();
                    } catch (SQLException e) {}
                }
            }
        %>
        <br/>
        <a href="adminDashboard.jsp" class="btn secondary-cta-btn">Back to Dashboard</a>
    </div>
    <jsp:include page="footer.jsp" />
</body>
</html>