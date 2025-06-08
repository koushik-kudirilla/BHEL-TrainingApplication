<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="utils.DBConnection, java.sql.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trainee Dashboard - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    
    <div class="container">
        <div class="hero">
            <div class="hero-content" aria-label="Trainee Dashboard Header">
                <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
                <h1>Trainee Dashboard</h1>
                <p>Manage Your Training Applications with Ease</p>
            </div>
        </div>
        <%
            // Check if user is authenticated
            String username = (String) session.getAttribute("username");
            String role = (String) session.getAttribute("role");
            if (username == null || role == null || !"Trainee".equals(role)) {
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

            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                conn = DBConnection.getConnection();

                String sql = "SELECT id FROM users WHERE username = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, username);
                rs = pstmt.executeQuery();
                int userId = 0;
                if (rs.next()) {
                    userId = rs.getInt("id");
                } else {
                    response.sendRedirect("traineeLogin.jsp");
                    return;
                }
                rs.close();
                pstmt.close();
        %>
        <div class="content">
            <h2>Quick Actions</h2>
            <div class="action-grid">
                <a href="applicationForm.jsp" class="action-card">
                    <span>Fill Application</span>
                    <p>Start a new training application.</p>
                </a>
                <a href="uploadDocuments.jsp" class="action-card">
                    <span>Upload Documents</span>
                    <p>Submit required documents for your application.</p>
                </a>
                <a href="viewApplications.jsp" class="action-card">
                    <span>View Applications</span>
                    <p>Check the status of your applications.</p>
                </a>
            </div>
            <h2>Your Training Applications</h2>
            <div class="table-container">
                <table class="dashboard-table" aria-label="Training Applications">
                    <thead>
                        <tr>
                            <th>Application ID</th>
                            <th>Training Type</th>
                            <th>Status</th>
                            <th>Schedule</th>
                            <th>Progress</th>
                            <th>Documents</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            sql = "SELECT a.id, a.training_required, a.status, a.institute_letter_path, a.aadhaar_path, a.photo_path, a.college_id_path, ts.schedule_id, ts.progress, s.training_type, s.start_date, s.end_date " +
                                  "FROM bhel_training_application a " +
                                  "LEFT JOIN trainee_schedules ts ON a.id = ts.application_id " +
                                  "LEFT JOIN training_schedules s ON ts.schedule_id = s.id " +
                                  "WHERE a.user_id = ?";
                            pstmt = conn.prepareStatement(sql);
                            pstmt.setInt(1, userId);
                            rs = pstmt.executeQuery();

                            boolean hasApplications = false;
                            while (rs.next()) {
                                hasApplications = true;
                                int appId = rs.getInt("id");
                                String trainingRequired = rs.getString("training_required");
                                String status = rs.getString("status");
                                String scheduleId = rs.getString("schedule_id");
                                String progress = rs.getString("progress");
                                String instituteLetterPath = rs.getString("institute_letter_path");
                                String aadhaarPath = rs.getString("aadhaar_path");
                                String photoPath = rs.getString("photo_path");
                                String collegeIdPath = rs.getString("college_id_path");

                                String scheduleDetails = scheduleId != null ? 
                                    rs.getString("training_type") + " (" + rs.getDate("start_date") + " to " + rs.getDate("end_date") + ")" : 
                                    "Not Assigned";
                                progress = (progress != null) ? progress : "N/A";
                                String documentsUploaded = (instituteLetterPath != null && aadhaarPath != null && photoPath != null && collegeIdPath != null) ? "Uploaded" : "Incomplete";
                        %>
                        <tr>
                            <td data-label="Application ID"><%= appId %></td>
                            <td data-label="Training Type"><%= trainingRequired %></td>
                            <td data-label="Status"><span class="status-box status-<%= status.toLowerCase() %>"><%= status %></span></td>
                            <td data-label="Schedule"><%= scheduleDetails %></td>
                            <td data-label="Progress"><%= progress %></td>
                            <td data-label="Documents"><%= documentsUploaded %></td>
                            <td data-label="Actions">
                                <%
                                    if ("pending".equals(status)) {
                                %>
                                <a href="editApplication.jsp?appId=<%= appId %>" class="btn action-btn">Edit</a>
                                <%
                                    }
                                    if ("Approved".equals(status)) {
                                %>
                                <a href="feeDetails.jsp?appId=<%= appId %>" class="btn action-btn">Fee Details</a>
                                <%
                                    }
                                    if (!"pending".equals(status) && !"Approved".equals(status)) {
                                %>
                                N/A
                                <%
                                    }
                                %>
                            </td>
                        </tr>
                        <%
                            }
                            if (!hasApplications) {
                        %>
                        <tr>
                            <td colspan="7">No applications found. Submit a new application to get started!</td>
                        </tr>
                        <%
                            }
                        %>
                    </tbody>
                </table>
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
            <p>Error: Unable to load dashboard. Please try again later.</p>
        </div>
        <%
                }
            } catch (Exception e) {
                e.printStackTrace();
        %>
        <div class="alert alert-error">
            <p>Error: Unable to load dashboard. Please try again later.</p>
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