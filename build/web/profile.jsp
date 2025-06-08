<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="utils.DBConnection" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Profile - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    <style>
        /* Internal styles for profile details */
        .profile-details {
            background: #ffffff;
            border-radius: 12px;
            padding: 30px;
            max-width: 500px;
            margin: 0 auto;
            box-shadow: 0 6px 18px rgba(0,0,0,0.15);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .profile-details:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 24px rgba(0,0,0,0.2);
        }

        .profile-details img.profile-pic-large {
            width: 160px;
            height: 160px;
            border: 4px solid #2c7a7b;
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
            margin: 0 auto 20px;
            display: block;
            transition: border-color 0.3s ease;
        }

        .profile-details img.profile-pic-large:hover {
            border-color: #d69e2e;
        }

        .profile-details p {
            font-size: 1.2em;
            margin: 12px 0;
            color: #2d3748;
            display: flex;
            align-items: center;
            padding: 8px 12px;
            border-radius: 6px;
            background: #f7fafc;
            transition: background 0.3s ease;
        }

        .profile-details p:hover {
            background: #e6fffa;
        }

        .profile-details p strong {
            color: #2c7a7b;
            font-weight: 600;
            width: 120px; /* Fixed width for labels */
            flex-shrink: 0; /* Prevent label from shrinking */
            text-align: left;
        }

        .profile-details p span {
            flex: 1;
            text-align: left;
            font-weight: 400;
            padding-left: 20px; /* Space between label and value */
            word-break: break-word; /* Handle long usernames */
        }

        .profile-details .action-buttons {
            margin-top: 30px;
            display: flex;
            gap: 15px;
            justify-content: center;
            flex-wrap: wrap;
        }

        .profile-details .btn.primary-btn {
            background: #d69e2e;
            padding: 12px 24px;
            font-size: 1em;
            font-weight: 500;
            transition: background 0.3s ease, transform 0.2s ease;
        }

        .profile-details .btn.primary-btn:hover {
            background: #b7791f;
            transform: scale(1.05);
        }

        .profile-details .btn.secondary-cta-btn {
            background: #6b7280;
            border: 2px solid #2c7a7b;
            padding: 12px 24px;
            font-size: 1em;
            font-weight: 500;
            transition: background 0.3s ease, transform 0.2s ease, border-color 0.3s ease;
        }

        .profile-details .btn.secondary-cta-btn:hover {
            background: #4b5563;
            border-color: #d69e2e;
            transform: scale(1.05);
        }

        /* Responsive adjustments */
        @media (max-width: 480px) {
            .profile-details {
                padding: 20px;
                max-width: 100%;
            }

            .profile-details img.profile-pic-large {
                width: 120px;
                height: 120px;
            }

            .profile-details p {
                font-size: 1em;
                flex-direction: column;
                align-items: flex-start;
                gap: 5px;
            }

            .profile-details p strong {
                width: auto;
            }

            .profile-details p span {
                padding-left: 0;
                text-align: left;
            }

            .profile-details .action-buttons {
                flex-direction: column;
                gap: 10px;
            }

            .profile-details .btn.primary-btn,
            .profile-details .btn.secondary-cta-btn {
                width: 100%;
                padding: 10px;
            }
        }
    </style>
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="hero">
        <div class="hero-content" aria-label="User Profile Header">
            <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
            <h1>Account Overview</h1>
            <p>Manage your account details</p>
        </div>
    </div>
    <div class="container">
        <%
            if (session.getAttribute("username") == null || session.getAttribute("role") == null) {
                response.sendRedirect("traineeLogin.jsp");
                return;
            }

            String profilePic = "images/profile.png";
            String email = "";
            try ( Connection conn = DBConnection.getConnection();
                 PreparedStatement pstmt = conn.prepareStatement("SELECT profile_pic, email FROM users WHERE username = ?")) {
                pstmt.setString(1, (String) session.getAttribute("username"));
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        profilePic = rs.getString("profile_pic") != null ? rs.getString("profile_pic") : profilePic;
                        email = rs.getString("email") != null ? rs.getString("email") : "Not set";
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
        %>
        <div class="content profile-card">
            <h2>Profile Details</h2>
            <div class="profile-details">
                <img src="<%= profilePic %>" alt="Profile Picture" class="profile-pic-large">
                <p><strong>Username:</strong> <span><%= session.getAttribute("username") %></span></p>
                <p><strong>Role:</strong> <span><%= session.getAttribute("role") %></span></p>
                <p><strong>Email:</strong> <span><%= email %></span></p>
                <div class="action-buttons" style="margin-left: 8px">
                    <a href="accountSettings.jsp" class="btn view-btn">Edit Profile</a>
                    <a href="changePassword.jsp" class="btn print-btn">Change Password</a>
                </div>
            </div>
        </div>
    </div>
    <jsp:include page="footer.jsp" />
</body>
</html>