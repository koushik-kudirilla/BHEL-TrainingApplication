<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.security.MessageDigest, javax.naming.*, java.util.logging.*" %>
<%@ page import="utils.DBConnection" %>
<%! private static final Logger LOGGER = Logger.getLogger("employeeLogin.jsp"); %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Employee Login - BHEL HRDC</title>
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
            padding-right: 40px;
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
            button.classList.add('btn-loading');
        }
        function togglePassword() {
            const passwordInput = document.getElementById('password');
            const toggleIcon = document.getElementById('togglePassword');
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
    <div class="container">
        <div class="login-container">
            <div class="login-card" aria-label="Employee Login">
                <h2>Employee Login</h2>
                <form action="employeeLogin.jsp" method="post" accept-charset="UTF-8" onsubmit="toggleLoading(this.querySelector('.btn'))" aria-label="Employee Login Form">
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email" id="email" name="email" required aria-label="Enter email">
                    </div>
                    <div class="form-group">
                        <label for="password">Password</label>
                        <div class="password-container">
                            <input type="password" id="password" name="password" required aria-label="Enter password">
                            <span class="toggle-password" id="togglePassword" onclick="togglePassword()">
                                <i class="fas fa-eye"></i>
                            </span>
                        </div>
                    </div>
                    <button type="submit" class="btn">Login</button>
                </form>
                <br>
                <%
                    if ("POST".equalsIgnoreCase(request.getMethod())) {
                        String email = request.getParameter("email");
                        String password = request.getParameter("password");

                        if (email != null && !email.trim().isEmpty() && password != null && !password.trim().isEmpty()) {
                            email = email.trim();
                            password = password.trim();

                            Connection conn = null;
                            PreparedStatement pstmt = null;
                            ResultSet rs = null;
                            try {
                                conn = DBConnection.getConnection();
                                String sql = "SELECT username, password, role FROM users WHERE email = ? AND role IN ('Admin', 'Trainer')";
                                pstmt = conn.prepareStatement(sql);
                                pstmt.setString(1, email);
                                rs = pstmt.executeQuery();

                                if (rs.next()) {
                                    String username = rs.getString("username");
                                    String storedPassword = rs.getString("password");
                                    String role = rs.getString("role");
                                    String[] parts = storedPassword.split(":");
                                    if (parts.length != 2) {
                                        throw new Exception("Invalid password format in database");
                                    }
                                    String storedSalt = parts[0];
                                    String storedHash = parts[1];
                                    byte[] saltBytes = hexToBytes(storedSalt);
                                    byte[] inputSaltedPassword = concatBytes(saltBytes, password.getBytes("UTF-8"));
                                    MessageDigest digest = MessageDigest.getInstance("SHA-256");
                                    byte[] inputHash = digest.digest(inputSaltedPassword);
                                    String inputHashHex = bytesToHex(inputHash);

                                    if (inputHashHex.equals(storedHash)) {
                                        session.setAttribute("username", username);
                                        session.setAttribute("role", role);
                                        String redirect = "Admin".equals(role) ? "adminDashboard.jsp" : "trainerDashboard.jsp";
                                        LOGGER.info("Login success: email=" + email + ", username=" + username + ", role=" + role);
                                        response.sendRedirect(redirect);
                                    } else {
                                        LOGGER.warning("Login failed: Invalid password for email=" + email);
                %>
                <div class="alert alert-error" role="alert">
                    <p>Invalid password.</p>
                </div>
                <%
                                    }
                                } else {
                                    LOGGER.warning("Login failed: Invalid email or not an Admin/Trainer for email=" + email);
                %>
                <div class="alert alert-error" role="alert">
                    <p>Invalid email or not an Admin/Trainer.</p>
                </div>
                <%
                                }
                            } catch (NamingException e) {
                                LOGGER.severe("NamingException: " + e.getMessage());
                %>
                <div class="alert alert-error" role="alert">
                    <p>Server configuration error. Please contact support.</p>
                </div>
                <%
                            } catch (SQLException e) {
                                LOGGER.severe("SQLException: " + e.getMessage());
                %>
                <div class="alert alert-error" role="alert">
                    <p>Database error: <%= e.getMessage() %></p>
                </div>
                <%
                            } catch (Exception e) {
                                LOGGER.severe("Unexpected error: " + e.getMessage());
                %>
                <div class="alert alert-error" role="alert">
                    <p>Unable to log in: <%= e.getMessage() %>. Please try again later.</p>
                </div>
                <%
                            } finally {
                                try { if (rs != null) rs.close(); } catch (SQLException ignored) {}
                                try { if (pstmt != null) pstmt.close(); } catch (SQLException ignored) {}
                                try { if (conn != null) conn.close(); } catch (SQLException ignored) {}
                            }
                        } else {
                            LOGGER.warning("Login failed: Empty email or password");
                %>
                <div class="alert alert-error" role="alert">
                    <p>Email and password are required.</p>
                </div>
                <%
                        }
                    }
                %>
                <p class="register-link">Trainee user? <a href="traineeLogin.jsp">Login here</a>.</p>
            </div>
        </div>
    </div>
    <jsp:include page="footer.jsp" />
    <%!
        private byte[] hexToBytes(String hex) {
            byte[] bytes = new byte[hex.length() / 2];
            for (int i = 0; i < hex.length(); i += 2) {
                bytes[i / 2] = (byte) Integer.parseInt(hex.substring(i, i + 2), 16);
            }
            return bytes;
        }

        private String bytesToHex(byte[] bytes) {
            StringBuilder hexString = new StringBuilder();
            for (byte b : bytes) {
                String hex = String.format("%02x", b & 0xff);
                hexString.append(hex);
            }
            return hexString.toString();
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