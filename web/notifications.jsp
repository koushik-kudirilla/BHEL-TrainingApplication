<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="utils.DBConnection" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Notifications - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="hero">
        <div class="hero-content" aria-label="Notifications Header">
            <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
            <h1>Notifications</h1>
            <p>Stay Updated with Your Alerts</p>
        </div>
    </div>
    <div class="container">
        <%
            if (session.getAttribute("username") == null || session.getAttribute("role") == null) {
                response.sendRedirect("traineeLogin.jsp");
                return;
            }

            int userId = 0;
            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement pstmt = conn.prepareStatement("SELECT id FROM users WHERE username = ?")) {
                pstmt.setString(1, (String) session.getAttribute("username"));
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        userId = rs.getInt("id");
                    } else {
                        response.sendRedirect("traineeLogin.jsp");
                        return;
                    }
                }
            } catch (SQLException e) {
        %>
        <div class="alert alert-error">
            <p>Database error: <%= e.getMessage() %>. Please try again later.</p>
        </div>
        <%
                return;
            }

            String sql = "";
            String role = (String) session.getAttribute("role");
            if ("Admin".equals(role)) {
                sql = "SELECT id, message, created_at FROM notifications WHERE role = 'Admin' OR (role = 'All' AND user_id = ?) ORDER BY created_at DESC";
            } else if ("Trainer".equals(role)) {
                sql = "SELECT id, message, created_at FROM notifications WHERE role = 'Trainer' OR (role = 'All' AND user_id = ?) ORDER BY created_at DESC";
            } else if ("Trainee".equals(role)) {
                sql = "SELECT id, message, created_at FROM notifications WHERE role = 'Trainee' OR (role = 'All' AND user_id = ?) ORDER BY created_at DESC";
            }

            try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/trainingDB", "root", "9392148628@abcd");
                 PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setInt(1, userId);
                try (ResultSet rs = pstmt.executeQuery()) {
        %>
        <div class="content">
            <h2>Your Notifications</h2>
            <div class="notification-list">
                <%
                    boolean hasNotifications = false;
                    while (rs.next()) {
                        hasNotifications = true;
                        int notificationId = rs.getInt("id");
                        String message = rs.getString("message");
                        Timestamp createdAt = rs.getTimestamp("created_at");
                %>
                <div class="notification-card" id="notification-<%= notificationId %>">
                    <p><span class="bullet">•</span> <%= message %></p>
                    <small><%= createdAt %></small>
                    <button class="btn action-btn" onclick="dismissNotification(<%= notificationId %>)">Dismiss</button>
                </div>
                <%
                    }
                    if (!hasNotifications) {
                %>
                <p>No notifications available.</p>
                <%
                    }
                %>
            </div>
        </div>
        <%
                }
            } catch (SQLException e) {
        %>
        <div class="alert alert-error">
            <p>Database error: <%= e.getMessage() %>. Please try again later.</p>
        </div>
        <%
            }
        %>
    </div>
    <div class="footer">
        <div class="footer-container">
            <p>BHEL HRDC | Bharat Heavy Electricals Limited</p>
            <p><a href="https://www.bhel.com" target="_blank">Official Website</a> | <a href="mailto:hrdc@bhel.com">hrdc@bhel.com</a> | <a href="tel:+914028581111">+91-40-28581111</a></p>
            <p>© 2025 BHEL. All rights reserved.</p>
        </div>
    </div>
    <script>
        function dismissNotification(id) {
            fetch('dismissNotification.jsp?id=' + id, { method: 'POST' })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const card = document.getElementById('notification-' + id);
                        card.style.opacity = '0';
                        setTimeout(() => card.remove(), 300);
                    } else {
                        alert('Error dismissing notification');
                    }
                });
        }
    </script>
</body>
</html>