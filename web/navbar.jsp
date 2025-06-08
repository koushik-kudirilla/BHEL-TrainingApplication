<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="utils.DBConnection, java.sql.*" %>
<div class="navbar">
    <div class="nav-container">
        <div class="nav-logo">
            <a href="index.jsp"><img src="images/bhel_logo.png" alt="BHEL Logo"></a>
        </div>
        <button class="nav-toggle" aria-expanded="false" aria-controls="nav-links" onclick="toggleNav()">
            <span></span><span></span><span></span>
        </button>
        <ul class="nav-links" id="nav-links">
            <li><a href="index.jsp">Home</a></li>
            <%
                
               
                String role = (String) session.getAttribute("role");
                String username = (String) session.getAttribute("username");
                String profilePic = "images/profile.png";
                
                if (username != null) {
                    try (Connection conn =  DBConnection.getConnection();
                         PreparedStatement pstmt = conn.prepareStatement("SELECT profile_pic FROM users WHERE username = ?")) {
                        pstmt.setString(1, username);
                        try (ResultSet rs = pstmt.executeQuery()) {
                            if (rs.next()) {
                                String dbProfilePic = rs.getString("profile_pic");
                                if (dbProfilePic != null && !dbProfilePic.isEmpty()) {
                                    profilePic = dbProfilePic;
                                }
                            }
                        }
                    } catch (SQLException e) {
                        // Log error, use default avatar
                    }
                }

                if (role != null) {
                    if ("Admin".equals(role)) {
            %>
            <li><a href="adminDashboard.jsp">Dashboard</a></li>
            <li class="profile">
                <a href="javascript:void(0)">Quick Actions</a>
                <div class="dropdown">
                    <a href="viewApplications.jsp"><span class="bullet">○</span> Manage Applications</a>
                    <a href="manageSchedules.jsp"><span class="bullet">○</span> Manage Schedules</a>
                    <a href="reports.jsp"><span class="bullet">○</span> Generate Reports</a>
                </div>
            </li>
            <%
                    } else if ("Trainer".equals(role)) {
            %>
            <li><a href="trainerDashboard.jsp">Dashboard</a></li>
            <li class="profile">
                <a href="javascript:void(0)">Quick Actions</a>
                <div class="dropdown">
                    <a href="viewApplications.jsp"><span class="bullet">○</span> View Applications</a>
                    <a href="updateProgress.jsp"><span class="bullet">○</span> Track Progress</a>
                    <a href="trainerSchedules.jsp"><span class="bullet">○</span> View Schedules</a>
                    <a href="reports.jsp"><span class="bullet">○</span> View Reports</a>
                </div>
            </li>
            <%
                    } else if ("Trainee".equals(role)) {
            %>
            <li><a href="traineeDashboard.jsp">Dashboard</a></li>
            <li class="profile">
                <a href="javascript:void(0)">Quick Actions</a>
                <div class="dropdown">
                    <a href="applicationForm.jsp"><span class="bullet">○</span> Fill Application</a>
                    <a href="uploadDocuments.jsp"><span class="bullet">○</span> Upload Documents</a>
                    <a href="viewApplications.jsp"><span class="bullet">○</span> View Applications</a>
                </div>
            </li>
            <%
                    }
                } else {
            %>
            <li><a href="register.jsp">Register</a></li>
            <li><a href="applicationForm.jsp">Trainee Application</a></li>
            <%
                }
            %>
            <li><a href="https://www.bhel.com" target="_blank">BHEL Home</a></li>
            <li><a href="https://www.bhel.com/contact-us" target="_blank">Contact Us</a></li>
            <%
                if (role == null || username == null) {
            %>
            <li><a href="traineeLogin.jsp" class="login-icon" aria-label="Login">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"></path>
                    <polyline points="10 17 15 12 10 7"></polyline>
                    <line x1="15" y1="12" x2="3" y2="12"></line>
                </svg>
            </a></li>
            <%
                }
                if (role != null && username != null) {
            %>
            <li class="profile">
                <div class="profile-link">
                    <img src="<%= profilePic %>" alt="Profile Picture" class="profile-pic">
                    <span class="profile-username"><%= username %></span>
                </div>
                <div class="dropdown" style =" left: auto; right: 0;">
                    <a href="profile.jsp"><span class="bullet">○</span> Profile</a>
                    <a href="accountSettings.jsp"><span class="bullet">○</span> Account Settings</a>
                    <a href="notifications.jsp"><span class="bullet">○</span> Notifications</a>
                    <a href="logout.jsp"><span class="bullet">○</span> Logout</a>
                </div>
            </li>
            <%
                }
            %>
        </ul>
    </div>
</div>
<script>
    function toggleNav() {
        const navLinks = document.getElementById('nav-links');
        const navToggle = document.querySelector('.nav-toggle');
        const isExpanded = navToggle.getAttribute('aria-expanded') === 'true';
        navToggle.setAttribute('aria-expanded', !isExpanded);
        navLinks.classList.toggle('active');
    }
</script>