<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Verification - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="login-container">
        <div class="login-card">
            <h2>Email Verification</h2>
            <div class="alert alert-info" role="alert">
                <p>Email verification is no longer required. You can log in directly.</p>
                <p><a href="traineeLogin.jsp">Proceed to Login</a></p>
            </div>
        </div>
    </div>
    <jsp:include page="footer.jsp" />
</body>
</html>