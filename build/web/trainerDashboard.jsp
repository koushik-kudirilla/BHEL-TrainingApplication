<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="utils.DBConnection, java.sql.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trainer Dashboard - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="hero">
        <div class="hero-content" aria-label="Trainer Dashboard Header">
            <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
            <h1>Trainer Dashboard</h1>
            <p>Oversee Training Schedules and Progress</p>
        </div>
    </div>
    <div class="container">
        <%
            String username = (String) session.getAttribute("username");
            String role = (String) session.getAttribute("role");
            if (username == null || role == null || !"Trainer".equals(role)) {
                response.sendRedirect("traineeLogin.jsp");
                return;
            }

            String message = request.getParameter("message");
            String error = request.getParameter("error");
            if (message != null) {
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

                String sql = "SELECT COUNT(*) FROM trainee_schedules";
                pstmt = conn.prepareStatement(sql);
                rs = pstmt.executeQuery();
                int assignedTrainees = 0;
                if (rs.next()) {
                    assignedTrainees = rs.getInt(1);
                }
                rs.close();
                pstmt.close();

                sql = "SELECT COUNT(*) FROM trainee_schedules WHERE progress = 'In Progress'";
                pstmt = conn.prepareStatement(sql);
                rs = pstmt.executeQuery();
                int inProgressTrainees = 0;
                if (rs.next()) {
                    inProgressTrainees = rs.getInt(1);
                }
        %>
        <div class="content">
            <h2>Training Overview</h2>
            <div class="dashboard-stats">
                <div class="stat-box">
                    <h3>Assigned Trainees</h3>
                    <p><%= assignedTrainees %></p>
                </div>
                <div class="stat-box">
                    <h3>In Progress Trainees</h3>
                    <p><%= inProgressTrainees %></p>
                </div>
            </div>
            <h2>Quick Actions</h2>
            <div class="action-grid">
                <a href="viewApplications.jsp" class="action-card">
                    <span>View Applications</span>
                    <p>Review trainee applications.</p>
                </a>
                <a href="updateProgress.jsp" class="action-card">
                    <span>Track Progress</span>
                    <p>Update trainee training progress.</p>
                </a>
                <a href="trainerSchedules.jsp" class="action-card">
                    <span>View Schedules</span>
                    <p>Check assigned training schedules.</p>
                </a>
                <a href="reports.jsp" class="action-card">
                    <span>View Reports</span>
                    <p>Generate and view training reports.</p>
                </a>
            </div>
        </div>
        <%
            } catch (SQLException e) {
                String sqlError = "Database error: " + e.getMessage();
        %>
        <div class="alert alert-error">
            <p><%= sqlError %>. Please try again later.</p>
        </div>
        <%
            } catch (Exception e) {
                String errorMsg = "Unexpected error: " + e.getMessage();
        %>
        <div class="alert alert-error">
            <p><%= errorMsg %>. Please try again later.</p>
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