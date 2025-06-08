<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, javax.naming.*, java.util.logging.*" %>
<%@ page import="utils.DBConnection" %>
<%! private static final Logger LOGGER = Logger.getLogger("accountSettings.jsp"); %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Account Settings - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    <style>
        /* Internal styles for settings form */
        .settings-content {
            background: #ffffff;
            border-radius: 12px;
            padding: 30px;
            max-width: 500px;
            margin: 0 auto;
            box-shadow: 0 6px 18px rgba(0,0,0,0.15);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .settings-content:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 24px rgba(0,0,0,0.2);
        }

        .settings-content h2 {
            color: #2c7a7b;
            font-size: 1.9em;
            margin-bottom: 20px;
            border-bottom: 2px solid #4fd1c5;
            padding-bottom: 8px;
            font-weight: 500;
            text-align: center;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            font-weight: 600;
            color: #2c7a7b;
            margin-bottom: 8px;
            font-size: 1.1em;
        }

        .form-group.profile-pic-group {
            text-align: center;
        }

        .form-group .profile-pic-preview {
            width: 120px;
            height: 120px;
            border-radius: 50%;
            margin: 10px auto;
            object-fit: cover;
            border: 2px solid #2c7a7b;
            display: block;
            transition: border-color 0.3s ease;
        }

        .form-group .profile-pic-preview:hover {
            border-color: #d69e2e;
        }

        .form-group input[type="file"] {
            margin: 10px auto;
            display: block;
        }

        .form-group.email-group {
            display: flex;
            align-items: center;
            padding: 8px 12px;
            border-radius: 6px;
            background: #f7fafc;
            transition: background 0.3s ease;
        }

        .form-group.email-group:hover {
            background: #e6fffa;
        }

        .form-group.email-group label {
            width: 100px;
            flex-shrink: 0;
            text-align: left;
            margin-bottom: 0;
        }

        .form-group.email-group input[type="email"] {
            flex: 1;
            padding: 8px;
            border: 1px solid #e2e8f0;
            border-radius: 5px;
            font-size: 1em;
            transition: border-color 0.3s, box-shadow 0.3s;
            margin-left: 20px;
        }

        .form-group.email-group input[type="email"]:focus {
            border-color: #d69e2e;
            box-shadow: 0 0 8px rgba(214,158,46,0.3);
            outline: none;
        }

        .action-buttons {
            margin-top: 30px;
            display: flex;
            gap: 15px;
            justify-content: center;
            flex-wrap: wrap;
        }

        .btn.secondary-btn {
            background: #6b7280;
            border: 2px solid #2c7a7b;
            padding: 8px 16px;
            font-size: 0.9em;
            transition: background 0.3s ease, transform 0.2s ease, border-color 0.3s ease;
        }

        .btn.secondary-btn:hover {
            background: #4b5563;
            border-color: #d69e2e;
            transform: scale(1.05);
        }

        .btn.primary-btn {
            background: #d69e2e;
            padding: 12px 24px;
            font-size: 1em;
            font-weight: 500;
            transition: background 0.3s ease, transform 0.2s ease;
        }

        .btn.primary-btn:hover {
            background: #b7791f;
            transform: scale(1.05);
        }

        .btn.change-password-btn {
            background: #2c7a7b;
            padding: 12px 24px;
            font-size: 1em;
            font-weight: 500;
            transition: background 0.3s ease, transform 0.2s ease;
        }

        .btn.change-password-btn:hover {
            background: #4fd1c5;
            transform: scale(1.05);
        }

        /* Responsive adjustments */
        @media (max-width: 480px) {
            .settings-content {
                padding: 20px;
                max-width: 100%;
            }

            .form-group .profile-pic-preview {
                width: 100px;
                height: 100px;
            }

            .form-group.email-group {
                flex-direction: column;
                align-items: flex-start;
                gap: 5px;
            }

            .form-group.email-group label {
                width: auto;
            }

            .form-group.email-group input[type="email"] {
                margin-left: 0;
                width: 100%;
            }

            .action-buttons {
                flex-direction: column;
                gap: 10px;
            }

            .btn.primary-btn,
            .btn.secondary-btn,
            .btn.change-password-btn {
                width: 100%;
                padding: 10px;
            }
        }
    </style>
    <script>
        function toggleLoading(button) {
            button.disabled = true;
            button.classList.add('loading');
        }

        function removeProfilePic() {
            fetch('<%= request.getContextPath() %>/RemoveProfilePicServlet', { method: 'POST' })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        document.querySelector('.profile-pic-preview').src = 'images/profile.png';
                        window.location.href = 'accountSettings.jsp?message=Profile+picture+removed';
                    } else {
                        window.location.href = 'accountSettings.jsp?error=' + encodeURIComponent(data.error);
                    }
                })
                .catch(error => {
                    window.location.href = 'accountSettings.jsp?error=' + encodeURIComponent('Error removing profile picture');
                });
        }
    </script>
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="hero">
        <div class="hero-content" aria-label="Account Settings Header">
            <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
            <h1>Account Settings</h1>
            <p>Manage Your Account Details</p>
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
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                conn = DBConnection.getConnection();
                pstmt = conn.prepareStatement("SELECT profile_pic, email FROM users WHERE username = ?");
                pstmt.setString(1, (String) session.getAttribute("username"));
                rs = pstmt.executeQuery();
                if (rs.next()) {
                    profilePic = rs.getString("profile_pic") != null ? rs.getString("profile_pic") : profilePic;
                    email = rs.getString("email") != null ? rs.getString("email") : "";
                }
            } catch (NamingException e) {
                LOGGER.severe("NamingException: " + e.getMessage());
        %>
        <div class="alert alert-error">
            <p>Server configuration error: Unable to connect to database.</p>
        </div>
        <%
                return;
            } catch (SQLException e) {
                LOGGER.severe("SQLException: " + e.getMessage());
        %>
        <div class="alert alert-error">
            <p>Database error: <%= e.getMessage() %>. Please try again later.</p>
        </div>
        <%
                return;
            } finally {
                try { if (rs != null) rs.close(); } catch (SQLException e) {}
                try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
                try { if (conn != null) conn.close(); } catch (SQLException e) {}
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
                document.getElementById("successMessage").style.display = "none";
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
        %>
        <div class="content settings-content">
            <h2>Update Account</h2>
            <form action="<%= request.getContextPath() %>/UpdateAccountServlet" method="post" enctype="multipart/form-data" onsubmit="toggleLoading(this.querySelector('.btn'))">
                <div class="form-group profile-pic-group">
                    <label for="profilePic">Profile Picture</label>
                    <img src="<%= profilePic %>" alt="Current Profile Picture" class="profile-pic-preview">
                    <input type="file" id="profilePic" name="profilePic" accept="image/*">
                    <button type="button" class="btn print-btn" onclick="removeProfilePic()">Remove Picture</button>
                </div>
                <div class="form-group email-group">
                    <label for="email">Email:</label>
                    <input type="email" id="email" name="email" value="<%= email %>" required>
                </div>
                <div class="action-buttons" style="margin-left: 8px">
                    <button type="submit" class="btn primary-btn">Save Changes</button>
                    <a href="changePassword.jsp" class="btn change-password-btn">Change Password</a>
                </div>
            </form>
        </div>
    </div>
    <jsp:include page="footer.jsp" />
</body>
</html>