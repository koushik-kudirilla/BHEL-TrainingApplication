<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="utils.DBConnection, java.sql.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>View Assigned Schedules - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="container">
        <div class="hero">
            <div class="hero-content" aria-label="View Assigned Schedules Header">
                <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
                <h1>View Assigned Schedules</h1>
                <p>Review Your Assigned Training Schedules</p>
            </div>
        </div>
        <%
            // Check if user is authenticated
            String username = (String) session.getAttribute("username");
            String role = (String) session.getAttribute("role");
            if (username == null || role == null || !"Trainer".equals(role)) {
                response.sendRedirect("login.jsp");
                return;
            }

            // Handle message display with time limit
            String message = request.getParameter("message");
            String timestampStr = request.getParameter("timestamp");
            boolean showMessage = false;

            if (message != null && timestampStr != null) {
                try {
                    long timestamp = Long.parseLong(timestampStr);
                    long currentTime = System.currentTimeMillis();
                    long timeDiffSeconds = (currentTime - timestamp) / 1000;
                    long timeLimitSeconds = 2;

                    if (timeDiffSeconds <= timeLimitSeconds) {
                        showMessage = true;
                    }
                } catch (NumberFormatException e) {
                    // Invalid timestamp
                }
            }

            String error = request.getParameter("error");
            if (showMessage) {
        %>
        <div id="successMessage" class="alert alert-success">
            <p><%= message.replace("+", " ") %></p>
        </div>
        <script>
            setTimeout(function() {
                var messageDiv = document.getElementById("successMessage");
                if (messageDiv) {
                    messageDiv.style.display = "none";
                }
            }, 2000);
        </script>
        <%
            } else if (error != null) {
        %>
        <div class="alert alert-error">
            <p><%= error.replace("+", " ") %></p>
        </div>
        <%
            }

            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;

            try {
                conn = DBConnection.getConnection();

                // Fetch schedules assigned to the trainer
                String sql = "SELECT s.id, s.training_type, s.training_period, s.start_date, s.end_date, s.capacity, " +
                             "(SELECT COUNT(*) FROM trainee_schedules ts WHERE ts.schedule_id = s.id) as assigned_trainees " +
                             "FROM training_schedules s " +
                             "WHERE s.trainer_id = (SELECT id FROM users WHERE username = ?) " +
                             "AND s.end_date >= CURDATE()";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, username);
                rs = pstmt.executeQuery();
        %>
        <div class="content">
            <h2>Your Assigned Schedules</h2>
            <div class="table-container">
                <table class="dashboard-table" aria-label="Assigned Training Schedules">
                    <thead>
                        <tr>
                            <th>Schedule ID</th>
                            <th>Training Type</th>
                            <th>Period</th>
                            <th>Start Date</th>
                            <th>End Date</th>
                            <th>Capacity</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            boolean hasSchedules = false;
                            while (rs.next()) {
                                hasSchedules = true;
                                int scheduleId = rs.getInt("id");
                                String trainingType = rs.getString("training_type");
                                String trainingPeriod = rs.getString("training_period");
                                String startDate = rs.getString("start_date");
                                String endDate = rs.getString("end_date");
                                int capacity = rs.getInt("capacity");
                                int assignedTrainees = rs.getInt("assigned_trainees");
                        %>
                        <tr>
                            <td data-label="Schedule ID"><%= scheduleId %></td>
                            <td data-label="Training Type"><%= trainingType %></td>
                            <td data-label="Period"><%= trainingPeriod %></td>
                            <td data-label="Start Date"><%= startDate %></td>
                            <td data-label="End Date"><%= endDate %></td>
                            <td data-label="Capacity"><%= assignedTrainees %>/<%= capacity %></td>
                        </tr>
                        <%
                            }
                            if (!hasSchedules) {
                        %>
                        <tr>
                            <td colspan="6">No active or upcoming schedules assigned to you.</td>
                        </tr>
                        <%
                            }
                        %>
                    </tbody>
                </table>
            </div>
            <div class="action-buttons">
                <a href="trainerDashboard.jsp" class="btn secondary-cta-btn">Back to Dashboard</a>
            </div>
        </div>
        <%
            } catch (SQLException e) {
                e.printStackTrace();
                if (e.getSQLState().equals("42S02")) {
        %>
        <div class="alert alert-error">
            <p>Error: Database table missing. Please ensure all tables are created.</p>
        </div>
        <%
                } else {
        %>
        <div class="alert alert-error">
            <p>Error: Unable to load schedules. Please try again later.</p>
        </div>
        <%
                }
            } catch (Exception e) {
                e.printStackTrace();
        %>
        <div class="alert alert-error">
            <p>Error: Unable to load schedules. Please try again later.</p>
        </div>
        <%
            } finally {
                if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
                if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
            }
        %>
    </div>
    <jsp:include page="footer.jsp" />
</body>
</html>