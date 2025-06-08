<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.security.MessageDigest, java.security.SecureRandom, javax.naming.*, java.util.logging.*" %>
<%@ page import="utils.DBConnection" %>
<%! private static final Logger LOGGER = Logger.getLogger("changePassword.jsp"); %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Change Password - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css" integrity="sha512-1ycn6IcaQQ40/MKBW2W4Rhis/DbILU74C1vSrLJxCq57o941Ym01SwNsOMqvEBFlcgUa6xLiPY/NS5R+E6ztJQ==" crossorigin="anonymous" referrerpolicy="no-referrer" />
    <style>
        .password-container {
            position: relative;
            width: 100%;
        }
        .password-container input[type="password"],
        .password-container input[type="text"] {
            width: 100%;
            padding-right: 40px; /* Space for icon */
            box-sizing: border-box;
        }
        .password-container .toggle-password {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            cursor: pointer;
            color: #666;
        }
        .password-container .toggle-password:hover {
            color: #000;
        }
    </style>
    <script>
        function toggleLoading(button) {
            button.disabled = true;
            button.classList.add('loading');
        }
        function togglePassword(fieldId, toggleId) {
            const passwordInput = document.getElementById(fieldId);
            const toggleIcon = document.getElementById(toggleId);
            if (passwordInput.type === 'password') {
                passwordInput.type = 'text';
                toggleIcon.classList.remove('fa-eye');
                toggleIcon.classList.add('fa-eye-slash');
            } else {
                passwordInput.type = 'password';
                toggleIcon.classList.remove('fa-eye-slash');
                toggleIcon.classList.add('fa-eye');
            }
        }
    </script>
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="login-container">
        <div class="login-card">
            <h2>Change Password</h2>
            <form action="changePassword.jsp" method="post" accept-charset="UTF-8" onsubmit="toggleLoading(this.querySelector('.btn'))" aria-label="Change Password Form">
                <div class="form-group">
                    <label for="currentPassword">Current Password:</label>
                    <div class="password-container">
                        <input type="password" id="currentPassword" name="currentPassword" required aria-label="Enter current password">
                        <span class="toggle-password" id="toggleCurrentPassword" onclick="togglePassword('currentPassword', 'toggleCurrentPassword')">
                            <i class="fas fa-eye"></i>
                        </span>
                    </div>
                </div>
                <div class="form-group">
                    <label for="newPassword">New Password:</label>
                    <div class="password-container">
                        <input type="password" id="newPassword" name="newPassword" required aria-label="Enter new password">
                        <span class="toggle-password" id="toggleNewPassword" onclick="togglePassword('newPassword', 'toggleNewPassword')">
                            <i class="fas fa-eye"></i>
                        </span>
                    </div>
                </div>
                <div class="form-group">
                    <label for="confirmPassword">Confirm New Password:</label>
                    <div class="password-container">
                        <input type="password" id="confirmPassword" name="confirmPassword" required aria-label="Confirm new password">
                        <span class="toggle-password" id="toggleConfirmPassword" onclick="togglePassword('confirmPassword', 'toggleConfirmPassword')">
                            <i class="fas fa-eye"></i>
                        </span>
                    </div>
                </div>
                <button type="submit" class="btn">Change Password</button>
            </form>
            <br>
            <%
                if ("POST".equalsIgnoreCase(request.getMethod())) {
                    // Ensure user is logged in
                    if (session.getAttribute("username") == null) {
                        response.sendRedirect("traineeLogin.jsp");
                        return;
                    }

                    String username = (String) session.getAttribute("username");
                    String currentPassword = request.getParameter("currentPassword");
                    String newPassword = request.getParameter("newPassword");
                    String confirmPassword = request.getParameter("confirmPassword");

                    if (currentPassword != null && !currentPassword.trim().isEmpty() &&
                        newPassword != null && !newPassword.trim().isEmpty() &&
                        confirmPassword != null && !confirmPassword.trim().isEmpty()) {
                        currentPassword = currentPassword.trim();
                        newPassword = newPassword.trim();
                        confirmPassword = confirmPassword.trim();

                        Connection conn = null;
                        PreparedStatement pstmt = null;
                        ResultSet rs = null;

                        try {
                            conn = DBConnection.getConnection();
                            conn.setAutoCommit(false); // Start transaction

                            // Fetch the stored password for the user
                            String fetchSql = "SELECT password FROM users WHERE username = ?";
                            pstmt = conn.prepareStatement(fetchSql);
                            pstmt.setString(1, username);
                            rs = pstmt.executeQuery();

                            if (rs.next()) {
                                String storedPassword = rs.getString("password");
                                String[] parts = storedPassword.split(":");
                                if (parts.length != 2) {
                                    throw new Exception("Invalid password format in database.");
                                }
                                String storedSalt = parts[0];
                                String storedHash = parts[1];

                                // Verify current password
                                byte[] salt = hexToBytes(storedSalt);
                                MessageDigest digest = MessageDigest.getInstance("SHA-256");
                                byte[] saltedCurrentPassword = concatBytes(salt, currentPassword.getBytes("UTF-8"));
                                byte[] currentHash = digest.digest(saltedCurrentPassword);
                                String computedHash = bytesToHex(currentHash);

                                if (!computedHash.equals(storedHash)) {
            %>
            <div class="alert alert-error" role="alert">
                <p>Error: Current password is incorrect.</p>
            </div>
            <%
                                } else if (!newPassword.equals(confirmPassword)) {
            %>
            <div class="alert alert-error" role="alert">
                <p>Error: New password and confirmation do not match.</p>
            </div>
            <%
                                } else {
                                    // Generate a new salt and hash for the new password
                                    SecureRandom random = new SecureRandom();
                                    byte[] newSalt = new byte[16];
                                    random.nextBytes(newSalt);
                                    byte[] saltedNewPassword = concatBytes(newSalt, newPassword.getBytes("UTF-8"));
                                    byte[] newHash = digest.digest(saltedNewPassword);
                                    String newHashedPassword = bytesToHex(newSalt) + ":" + bytesToHex(newHash);

                                    // Update the password in the database
                                    String updateSql = "UPDATE users SET password = ? WHERE username = ?";
                                    pstmt = conn.prepareStatement(updateSql);
                                    pstmt.setString(1, newHashedPassword);
                                    pstmt.setString(2, username);
                                    pstmt.executeUpdate();

                                    conn.commit(); // Commit transaction
                                    LOGGER.info("Password changed for user: " + username);
            %>
            <div class="alert alert-success" role="alert">
                <p>Password changed successfully!</p>
                <p><a href="profile.jsp">Return to Profile</a></p>
            </div>
            <%
                                }
                            } else {
            %>
            <div class="alert alert-error" role="alert">
                <p>Error: User not found.</p>
            </div>
            <%
                            }
                        } catch (NamingException e) {
                            LOGGER.severe("NamingException: " + e.getMessage());
            %>
            <div class="alert alert-error" role="alert">
                <p>Server configuration error: Unable to connect to database.</p>
            </div>
            <%
                        } catch (SQLException e) {
                            try { if (conn != null) conn.rollback(); } catch (SQLException ex) {}
                            LOGGER.severe("SQLException: " + e.getMessage());
            %>
            <div class="alert alert-error" role="alert">
                <p>Database error: <%= e.getMessage() %></p>
            </div>
            <%
                        } catch (Exception e) {
                            try { if (conn != null) conn.rollback(); } catch (SQLException ex) {}
                            LOGGER.severe("Unexpected error: " + e.getMessage());
                            e.printStackTrace();
            %>
            <div class="alert alert-error" role="alert">
                <p>Unable to change password: <%= e.getMessage() %>. Please try again or contact support.</p>
            </div>
            <%
                        } finally {
                            try { if (rs != null) rs.close(); } catch (SQLException e) {}
                            try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
                            try { if (conn != null) { conn.setAutoCommit(true); conn.close(); } } catch (SQLException e) {}
                        }
                    } else {
            %>
            <div class="alert alert-error" role="alert">
                <p>All fields are required.</p>
            </div>
            <%
                    }
                }
            %>
            <p class="register-link">Back to <a href="profile.jsp">Profile</a>.</p>
        </div>
    </div>
    <jsp:include page="footer.jsp" />
    <%!
        private String bytesToHex(byte[] bytes) {
            StringBuilder hexString = new StringBuilder();
            for (byte b : bytes) {
                String hex = String.format("%02x", b & 0xff);
                hexString.append(hex);
            }
            return hexString.toString();
        }

        private byte[] hexToBytes(String hex) {
            int len = hex.length();
            byte[] data = new byte[len / 2];
            for (int i = 0; i < len; i += 2) {
                data[i / 2] = (byte) ((Character.digit(hex.charAt(i), 16) << 4)
                                     + Character.digit(hex.charAt(i+1), 16));
            }
            return data;
        }

        private byte[] concatBytes(byte[] salt, byte[] password) {
            byte[] combined = new byte[salt.length + password.length];
            System.arraycopy(salt, 0, combined, 0, salt.length);
            System.arraycopy(password, 0, combined, salt.length, password.length);
            return combined;
        }
    %>
</body>
</html>