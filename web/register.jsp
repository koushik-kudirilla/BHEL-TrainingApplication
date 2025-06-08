<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.security.MessageDigest, java.security.SecureRandom, javax.naming.*, java.util.logging.*" %>
<%@ page import="utils.DBConnection" %>
<%! private static final Logger LOGGER = Logger.getLogger("register.jsp"); %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trainee Registration - BHEL HRDC</title>
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
    <div class="login-container">
        <div class="login-card">
            <h2>Trainee Registration</h2>
            <form action="register.jsp" method="post" accept-charset="UTF-8" onsubmit="toggleLoading(this.querySelector('.btn'))" aria-label="Trainee Registration Form">
                <div class="form-group">
                    <label for="username">Username:</label>
                    <input type="text" id="username" name="username" required aria-label="Enter username">
                </div>
                <div class="form-group">
                    <label for="email">Email:</label>
                    <input type="email" id="email" name="email" required aria-label="Enter email">
                </div>
                <div class="form-group">
                    <label for="password">Password:</label>
                    <div class="password-container">
                        <input type="password" id="password" name="password" required aria-label="Enter password">
                        <span class="toggle-password" id="togglePassword" onclick="togglePassword()">
                            <i class="fas fa-eye"></i>
                        </span>
                    </div>
                </div>
                <button type="submit" class="btn">Register</button>
            </form>
            <br>
            <%
                if ("POST".equalsIgnoreCase(request.getMethod())) {
                    String usernameInput = request.getParameter("username");
                    String email = request.getParameter("email");
                    String password = request.getParameter("password");

                    if (usernameInput != null && !usernameInput.trim().isEmpty() && 
                        email != null && !email.trim().isEmpty() && 
                        password != null && !password.trim().isEmpty()) {
                        usernameInput = usernameInput.trim();
                        email = email.trim();
                        password = password.trim();

                        Connection conn = null;
                        PreparedStatement pstmt = null;
                        ResultSet rs = null;
                        boolean emailExists = false;

                        try {
                            conn = DBConnection.getConnection();
                            conn.setAutoCommit(false); // Start transaction

                            // Check if email already exists
                            String checkSql = "SELECT email FROM users WHERE email = ?";
                            pstmt = conn.prepareStatement(checkSql);
                            pstmt.setString(1, email);
                            rs = pstmt.executeQuery();
                            if (rs.next()) {
                                emailExists = true;
            %>
            <div class="alert alert-error" role="alert">
                <p>Error: Email already exists.</p>
            </div>
            <%
                            } else {
                                // Generate a random salt
                                SecureRandom random = new SecureRandom();
                                byte[] salt = new byte[16];
                                random.nextBytes(salt);

                                // Hash the password with salt
                                MessageDigest digest = MessageDigest.getInstance("SHA-256");
                                byte[] saltedPassword = concatBytes(salt, password.getBytes("UTF-8"));
                                byte[] hash = digest.digest(saltedPassword);
                                String hashedPassword = bytesToHex(salt) + ":" + bytesToHex(hash);

                                // Insert user into the database
                                String insertSql = "INSERT INTO users (username, password, role, email, created_at) VALUES (?, ?, 'Trainee', ?, CURRENT_TIMESTAMP)";
                                pstmt = conn.prepareStatement(insertSql);
                                pstmt.setString(1, usernameInput);
                                pstmt.setString(2, hashedPassword);
                                pstmt.setString(3, email);
                                pstmt.executeUpdate();

                                conn.commit(); // Commit transaction
                                LOGGER.info("User registered: " + usernameInput);
            %>
            <div class="alert alert-success" role="alert">
                <p>Registration successful! You can now log in.</p>
                <p><a href="traineeLogin.jsp">Proceed to Login</a></p>
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
                            if (e.getSQLState().equals("23000")) {
            %>
            <div class="alert alert-error" role="alert">
                <p>Error: Username already exists.</p>
            </div>
            <%
                            } else {
            %>
            <div class="alert alert-error" role="alert">
                <p>Database error: <%= e.getMessage() %></p>
            </div>
            <%
                            }
                        } catch (Exception e) {
                            try { if (conn != null) conn.rollback(); } catch (SQLException ex) {}
                            LOGGER.severe("Unexpected error: " + e.getMessage());
                            e.printStackTrace();
            %>
            <div class="alert alert-error" role="alert">
                <p>Unable to register: <%= e.getMessage() %>. Please try again or contact support.</p>
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
            <p class="register-link">Already have an account? <a href="traineeLogin.jsp">Login here</a>.</p>
            <p class="register-link">Admin or Trainer? <a href="employeeLogin.jsp">Login as Employee</a>.</p>
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

        private byte[] concatBytes(byte[] salt, byte[] password) {
            byte[] combined = new byte[salt.length + password.length];
            System.arraycopy(salt, 0, combined, 0, salt.length);
            System.arraycopy(password, 0, combined, salt.length, password.length);
            return combined;
        }
    %>
</body>
</html>