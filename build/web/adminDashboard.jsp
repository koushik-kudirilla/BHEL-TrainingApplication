<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="utils.DBConnection, java.sql.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="hero">
        <div class="hero-content" aria-label="Admin Dashboard Header">
            <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
            <h1>Admin Dashboard</h1>
            <p>Manage Training Applications and Schedules</p>
        </div>
    </div>
    <div class="container">
        <%
            String username = (String) session.getAttribute("username");
            String role = (String) session.getAttribute("role");
            if (username == null || role == null || !"Admin".equals(role)) {
                response.sendRedirect("traineeLogin.jsp");
                return;
            }

            try (Connection conn = DBConnection.getConnection()) {
                // Count pending applications
                String sql = "SELECT COUNT(*) FROM bhel_training_application WHERE status = 'pending'";
                try (PreparedStatement pstmt = conn.prepareStatement(sql);
                     ResultSet rs = pstmt.executeQuery()) {
                    int pendingApps = rs.next() ? rs.getInt(1) : 0;

                    // Count active schedules
                    sql = "SELECT COUNT(*) FROM training_schedules WHERE CURDATE() BETWEEN start_date AND end_date";
                    try (PreparedStatement pstmt2 = conn.prepareStatement(sql);
                         ResultSet rs2 = pstmt2.executeQuery()) {
                        int activeSchedules = rs2.next() ? rs2.getInt(1) : 0;
        %>
        <div class="content">
            <h2>System Overview</h2>
            <div class="dashboard-stats">
                <div class="stat-box">
                    <h3>Pending Applications</h3>
                    <p><%= pendingApps %></p>
                </div>
                <div class="stat-box">
                    <h3>Active Schedules</h3>
                    <p><%= activeSchedules %></p>
                </div>
            </div>
            <h2>Quick Actions</h2>
            <div class="action-grid">
                <a href="viewApplications.jsp" class="action-card">
                    <span>Manage Applications</span>
                    <p>Review and approve trainee applications.</p>
                </a>
                <a href="manageSchedules.jsp" class="action-card">
                    <span>Manage Schedules</span>
                    <p>Create and update training schedules.</p>
                </a>
                <a href="reports.jsp" class="action-card">
                    <span>Generate Reports</span>
                    <p>View and export training reports.</p>
                </a>
            </div>
        </div>
        <%
                    }
                }
            } catch (SQLException e) {
                String errorMsg = "Database error: " + e.getMessage();
        %>
        <div class="alert alert-error">
            <p><%= errorMsg %>. Please try again later.</p>
        </div>
        <%
            } catch (Exception e) {
                String errorMsg = "Unexpected error: " + e.getMessage();
        %>
        <div class="alert alert-error">
            <p><%= errorMsg %>. Please try again later.</p>
        </div>
        <%
            }
        %>
    </div>
    <jsp:include page="footer.jsp" />
</body>
</html>