<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="utils.DBConnection, java.sql.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Update Trainee Progress - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="container">
        <div class="hero">
            <div class="hero-content" aria-label="Update Trainee Progress Header">
                <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
                <h1>Update Trainee Progress</h1>
                <p>Manage Trainee Progress for Your Schedules</p>
            </div>
        </div>
        <%
            // Check if user is authenticated
            String username = (String) session.getAttribute("username");
            String role = (String) session.getAttribute("role");
            if (username == null || role == null || !"Trainer".equals(role)) {
                response.sendRedirect("traineeLogin.jsp");
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

            // Handle progress update
            if ("POST".equalsIgnoreCase(request.getMethod())) {
                String applicationId = request.getParameter("applicationId");
                String scheduleId = request.getParameter("scheduleId");
                String newProgress = request.getParameter("progress");
                Connection conn = null;
                PreparedStatement pstmt = null;

                try {
                    conn = DBConnection.getConnection();

                    String updateSql = "UPDATE trainee_schedules ts " +
                                      "SET progress = ? " +
                                      "WHERE ts.application_id = ? AND ts.schedule_id = ? " +
                                      "AND ts.schedule_id IN (SELECT id FROM training_schedules WHERE trainer_id = (SELECT id FROM users WHERE username = ?))";
                    pstmt = conn.prepareStatement(updateSql);
                    pstmt.setString(1, newProgress);
                    pstmt.setInt(2, Integer.parseInt(applicationId));
                    pstmt.setInt(3, Integer.parseInt(scheduleId));
                    pstmt.setString(4, username);
                    int rows = pstmt.executeUpdate();

                    if (rows > 0) {
                        message = "Progress updated successfully for application ID " + applicationId + ".";
                    } else {
                        error = "Failed to update progress or unauthorized.";
                    }
                } catch (SQLException e) {
                    error = "Error updating progress: " + e.getMessage();
                    e.printStackTrace();
                } catch (Exception e) {
                    error = "Unexpected error: " + e.getMessage();
                    e.printStackTrace();
                } finally {
                    if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
                    if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                }
                response.sendRedirect("updateProgress.jsp" + (message != null ? "?message=" + message.replace(" ", "+") + "&timestamp=" + System.currentTimeMillis() : error != null ? "?error=" + error.replace(" ", "+") : ""));
                return;
            }

            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;

            try {
                conn = DBConnection.getConnection();

                // Fetch trainee schedules for the trainer
                String sql = "SELECT ts.application_id, ts.schedule_id, a.applicant_name, a.training_required, s.training_type, s.start_date, s.end_date, ts.progress " +
                             "FROM trainee_schedules ts " +
                             "JOIN bhel_training_application a ON ts.application_id = a.id " +
                             "JOIN training_schedules s ON ts.schedule_id = s.id " +
                             "WHERE s.trainer_id = (SELECT id FROM users WHERE username = ?) " +
                             "AND s.end_date >= CURDATE()";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, username);
                rs = pstmt.executeQuery();
        %>
        <div class="content">
            <h2>Trainee Schedules</h2>
            <div class="table-container">
                <table class="dashboard-table" aria-label="Trainee Schedules">
                    <thead>
                        <tr>
                            <th>Application</th>
                            <th>Trainee</th>
                            <th>Training Type</th>
                            <th>Schedule Type</th>
                            <th>Start Date</th>
                            <th>End Date</th>
                            <th>Current Progress</th>
                            <th>Update Progress</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            boolean hasTrainees = false;
                            while (rs.next()) {
                                hasTrainees = true;
                                int applicationId = rs.getInt("application_id");
                                int scheduleId = rs.getInt("schedule_id");
                                String applicantName = rs.getString("applicant_name");
                                String trainingRequired = rs.getString("training_required");
                                String trainingType = rs.getString("training_type");
                                String startDate = rs.getString("start_date");
                                String endDate = rs.getString("end_date");
                                String progress = rs.getString("progress");
                        %>
                        <tr>
                            <td data-label="Application ID"><%= applicationId %></td>
                            <td data-label="Trainee"><%= applicantName %></td>
                            <td data-label="Training Requested"><%= trainingRequired %></td>
                            <td data-label="Schedule Type"><%= trainingType %></td>
                            <td data-label="Start Date"><%= startDate %></td>
                            <td data-label="End Date"><%= endDate %></td>
                            <td data-label="Current Progress"><%= progress != null ? progress : "N/A" %></td>
                            <td data-label="Update Progress">
                                <form action="updateProgress.jsp" method="post">
                                    <input type="hidden" name="applicationId" value="<%= applicationId %>">
                                    <input type="hidden" name="scheduleId" value="<%= scheduleId %>">
                                    <select name="progress" required>
                                        <option value="Not Started" <%= "Not Started".equals(progress) ? "selected" : "" %>>Not Started</option>
                                        <option value="In Progress" <%= "In Progress".equals(progress) ? "selected" : "" %>>Active</option>
                                        <option value="Completed" <%= "Completed".equals(progress) ? "selected" : "" %>>Completed</option>
                                        <option value="Failed" <%= "Failed".equals(progress) ? "selected" : "" %>>Failed</option>
                                        <option value="Cancelled" <%= "Cancelled".equals(progress) ? "selected" : "" %>>Cancelled</option>
                                    </select>
                                    <button type="submit" class="btn action-btn">Update</button>
                                </form>
                            </td>
                        </tr>
                        <%
                            }
                            if (!hasTrainees) {
                        %>
                        <tr>
                            <td colspan="8">No trainees assigned to your active schedules.</td>
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
            <p>Error: Unable to load trainee schedules. Please try again later.</p>
        </div>
        <%
                }
            } catch (Exception e) {
                e.printStackTrace();
        %>
        <div class="alert alert-error">
            <p>Error: Unable to load trainee schedules. Please try again later.</p>
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