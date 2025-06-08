<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, utils.DBConnection" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Application - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    <%
        String trainingPeriod = "";
    %>
    <style>
        .form-group {
            margin-bottom: 20px;
            position: relative;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            color: #2c7a7b;
        }
        .form-group input, .form-group select, .form-group textarea {
            width: 100%;
            padding: 12px;
            box-sizing: border-box;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            font-size: 1em;
            transition: border-color 0.3s, box-shadow 0.3s;
        }
        .form-group input:focus, .form-group select:focus, .form-group textarea:focus {
            border-color: #d69e2e;
            box-shadow: 0 0 8px rgba(214,158,46,0.3);
            outline: none;
        }
        .error-message {
            color: #9b2c2c;
            background-color: #fed7d7;
            border: 1px solid #f6ad55;
            padding: 8px 12px;
            margin-top: 5px;
            border-radius: 5px;
            font-size: 0.9em;
            display: none;
        }
        .error-message.active {
            display: block;
        }
        .form-group.inline {
            display: flex;
            gap: 20px;
        }
        .form-group.inline > div {
            flex: 1;
        }
        .form-group.read-only {
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
        }
        .form-group.read-only label {
            font-weight: bold;
        }
    </style>
    <script>
        const touchedFields = new Set();

        function validateTextInput(value, minLength) {
            const regex = /^[A-Za-z\s]+$/;
            return value.length >= minLength && regex.test(value);
        }

        function validateDateOfBirth(value) {
            const dob = new Date(value);
            const today = new Date();
            let age = today.getFullYear() - dob.getFullYear();
            const monthDiff = today.getMonth() - dob.getMonth();
            if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
                age--;
            }
            return dob instanceof Date && !isNaN(dob) && age >= 15;
        }

        function validatePhoneNumber(value) {
            const regex = /^\d{10}$/;
            return regex.test(value);
        }

        function validateAadhaar(value) {
            const regex = /^\d{12}$/;
            return regex.test(value);
        }

        function validateEmail(value) {
            const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            return regex.test(value);
        }

        function validateAddress(value) {
            return value.length >= 10;
        }

        function validateDropdown(value) {
            return value !== "";
        }

        function toggleError(inputElement, message, isValid) {
            let errorElement = inputElement.nextElementSibling;
            if (!errorElement || !errorElement.classList.contains('error-message')) {
                errorElement = document.createElement('span');
                errorElement.className = 'error-message';
                inputElement.parentNode.insertBefore(errorElement, inputElement.nextSibling);
            }
            errorElement.innerText = isValid ? '' : message;
            errorElement.classList.toggle('active', !isValid);
        }

        function validateInput(inputElement, forceShowError = false) {
            const name = inputElement.name;
            const value = inputElement.value.trim();
            const isTouched = touchedFields.has(inputElement) || forceShowError;

            if (!isTouched && value === '') {
                toggleError(inputElement, '', true);
                return;
            }

            let isValid = false;
            let errorMessage = '';

            switch (name) {
                case 'applicant_name':
                case 'institute_name':
                case 'guardian_name':
                    isValid = validateTextInput(value, 4);
                    errorMessage = 'Must be at least 4 alphabetic characters.';
                    break;
                case 'trade':
                    isValid = validateTextInput(value, 4);
                    errorMessage = 'Must be at least 4 alphabetic characters (e.g., Mechanical).';
                    break;
                case 'dob':
                    isValid = validateDateOfBirth(value);
                    errorMessage = 'Must be a valid date, and applicant must be at least 15 years old.';
                    break;
                case 'contact_number':
                    isValid = validatePhoneNumber(value);
                    errorMessage = 'Must be exactly 10 digits.';
                    break;
                case 'aadhaar_number':
                    isValid = validateAadhaar(value);
                    errorMessage = 'Must be exactly 12 digits.';
                    break;
                case 'email':
                    isValid = validateEmail(value);
                    errorMessage = 'Must be a valid email address.';
                    break;
                case 'address':
                    isValid = validateAddress(value);
                    errorMessage = 'Must be at least 10 characters.';
                    break;
                case 'so_do':
                    isValid = value === '' || validateTextInput(value, 4);
                    errorMessage = 'Must be at least 4 alphabetic characters (e.g., S/o John).';
                    break;
                case 'training_required':
                case 'training_program':
                case 'training_period':
                case 'gender':
                case 'year_of_study':
                    isValid = validateDropdown(value);
                    errorMessage = 'Please select an option.';
                    break;
            }

            toggleError(inputElement, errorMessage, isValid);
        }

        function initializeValidation() {
            const inputs = document.querySelectorAll('input, select, textarea');
            inputs.forEach(input => {
                if (['roll_no', 'batch', 'sub_caste'].includes(input.name)) {
                    return;
                }
                input.addEventListener('input', () => {
                    touchedFields.add(input);
                    validateInput(input);
                });
                input.addEventListener('change', () => {
                    touchedFields.add(input);
                    validateInput(input, true);
                });
                input.addEventListener('blur', () => {
                    touchedFields.add(input);
                    validateInput(input, true);
                });
            });
        }

        function showTrainingPeriod() {
            var program = document.getElementById("training_program").value;
            var periodDiv = document.getElementById("training_period_div");
            var periodSelect = document.getElementById("training_period");
            var hiddenPeriodInput = document.getElementById("hidden_training_period");

            if (program === "Diploma (6 Months)") {
                periodDiv.style.display = "none";
                periodSelect.value = "6 months";
                periodSelect.disabled = true;
                hiddenPeriodInput.value = "6 months";
            } else if (program === "Graduate (3 Years)" || program === "Graduate (4 Years)" || program === "Postgraduate") {
                periodDiv.style.display = "block";
                periodSelect.disabled = false;
                periodSelect.innerHTML = "";
                var options = ["", "1 month", "2 months", "3 months", "4 months", "5 months", "6 months"];
                for (var i = 0; i < options.length; i++) {
                    var option = document.createElement("option");
                    option.value = options[i];
                    option.text = options[i] || "Select Training Period";
                    periodSelect.appendChild(option);
                }
                periodSelect.value = "<%= trainingPeriod %>".toLowerCase();
                hiddenPeriodInput.value = periodSelect.value;
            } else {
                periodDiv.style.display = "none";
                periodSelect.value = "";
                periodSelect.disabled = true;
                hiddenPeriodInput.value = "";
            }
            validateInput(periodSelect, touchedFields.has(periodSelect));
        }

        function updateHiddenPeriod() {
            var periodSelect = document.getElementById("training_period");
            var hiddenPeriodInput = document.getElementById("hidden_training_period");
            hiddenPeriodInput.value = periodSelect.value;
            validateInput(periodSelect, true);
        }

        window.onload = function() {
            showTrainingPeriod();
            initializeValidation();
        };
    </script>
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="container">
        <div class="hero">
            <div class="hero-content">
                <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
                <h1>Edit Application for Training at BHEL HRDC</h1>
                <p>Update your application details below</p>
            </div>
        </div>
        <%
            String username = (String) session.getAttribute("username");
            String role = (String) session.getAttribute("role");
            if (username == null || role == null || !"Trainee".equals(role)) {
                response.sendRedirect("login.jsp");
                return;
            }

            String appIdParam = request.getParameter("appId");
            if (appIdParam == null || appIdParam.trim().isEmpty()) {
                response.sendRedirect("traineeDashboard.jsp?error=Missing+application+ID");
                return;
            }

            int appId;
            try {
                appId = Integer.parseInt(appIdParam);
            } catch (NumberFormatException e) {
                response.sendRedirect("traineeDashboard.jsp?error=Invalid+application+ID+format");
                return;
            }

            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                conn = DBConnection.getConnection();
                String sql = "SELECT * FROM bhel_training_application WHERE id = ? AND user_id = (SELECT id FROM users WHERE username = ?) AND status = 'pending'";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, appId);
                pstmt.setString(2, username);
                rs = pstmt.executeQuery();

                if (!rs.next()) {
                    response.sendRedirect("traineeDashboard.jsp?error=Application+not+found+or+not+editable");
                    return;
                }

                String applicantName = rs.getString("applicant_name");
                String instituteName = rs.getString("institute_name");
                String trade = rs.getString("trade");
                String rollNo = rs.getString("roll_no");
                String batch = rs.getString("batch");
                String yearOfStudy = rs.getString("year_of_study");
                String dob = rs.getString("dob");
                String guardianName = rs.getString("guardian_name");
                String soDo = rs.getString("so_do");
                String address = rs.getString("address");
                String contactNumber = rs.getString("contact_number");
                String aadhaarNumber = rs.getString("aadhaar_number");
                String trainingRequired = rs.getString("training_required");
                String trainingProgram = rs.getString("training_program");
                trainingPeriod = rs.getString("training_period") != null ? rs.getString("training_period") : "";
                double trainingFee = rs.getDouble("training_fee");
                String subCaste = rs.getString("sub_caste");
                String email = rs.getString("email");
                String gender = rs.getString("gender");
        %>
        <div class="content">
            <form action="UpdateApplicationServlet" method="post">
                <input type="hidden" name="app_id" value="<%= appId %>">
                <div class="form-group">
                    <label>1. Applicant Name:</label>
                    <input type="text" name="applicant_name" value="<%= applicantName != null ? applicantName : "" %>" required>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>2. Institute Name:</label>
                    <input type="text" name="institute_name" value="<%= instituteName != null ? instituteName : "" %>" required>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>3. Trade / Diploma / Degree / PG:</label>
                    <input type="text" name="trade" value="<%= trade != null ? trade : "" %>" required>
                    <span class="error-message"></span>
                </div>
                <div class="form-group inline">
                    <div>
                        <label>4. Roll No:</label>
                        <input type="text" name="roll_no" value="<%= rollNo != null ? rollNo : "" %>" required>
                    </div>
                    <div>
                        <label>Batch:</label>
                        <input type="text" name="batch" value="<%= batch != null ? batch : "" %>" required>
                    </div>
                    <div>
                        <label>Year of Study:</label>
                        <select name="year_of_study" required>
                            <option value="">Select Year of Study</option>
                            <option value="1st Year" <%= "1st Year".equals(yearOfStudy) ? "selected" : "" %>>1st Year</option>
                            <option value="2nd Year" <%= "2nd Year".equals(yearOfStudy) ? "selected" : "" %>>2nd Year</option>
                            <option value="3rd Year" <%= "3rd Year".equals(yearOfStudy) ? "selected" : "" %>>3rd Year</option>
                            <option value="4th Year" <%= "4th Year".equals(yearOfStudy) ? "selected" : "" %>>4th Year</option>
                        </select>
                        <span class="error-message"></span>
                    </div>
                </div>
                <div class="form-group">
                    <label>5. Date of Birth (YYYY-MM-DD):</label>
                    <input type="date" name="dob" value="<%= dob != null ? dob : "" %>" required>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>6. Father's / Guardian's Name:</label>
                    <input type="text" name="guardian_name" value="<%= guardianName != null ? guardianName : "" %>" required>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>7. S/o or D/o or C/o:</label>
                    <input type="text" name="so_do" value="<%= soDo != null ? soDo : "" %>">
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>8. Address for Communication:</label>
                    <textarea name="address" rows="3" required><%= address != null ? address : "" %></textarea>
                    <span class="error-message"></span>
                </div>
                <div class="form-group inline">
                    <div>
                        <label>9. Contact Mobile No:</label>
                        <input type="text" name="contact_number" value="<%= contactNumber != null ? contactNumber : "" %>" required>
                        <span class="error-message"></span>
                    </div>
                    <div>
                        <label>Aadhaar No:</label>
                        <input type="text" name="aadhaar_number" value="<%= aadhaarNumber != null ? aadhaarNumber : "" %>" required>
                        <span class="error-message"></span>
                    </div>
                </div>
                <div class="form-group">
                    <label>10. Training Required:</label>
                    <select name="training_required" required>
                        <option value="">Select Training Type</option>
                        <option value="internship" <%= "internship".equalsIgnoreCase(trainingRequired) ? "selected" : "" %>>Internship</option>
                        <option value="TRAINING" <%= "TRAINING".equalsIgnoreCase(trainingRequired) ? "selected" : "" %>>Training</option>
                    </select>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>11. Training Program:</label>
                    <select id="training_program" name="training_program" onchange="showTrainingPeriod()" required>
                        <option value="">Select Training Program</option>
                        <option value="Diploma (6 Months)" <%= "Diploma (6 Months)".equals(trainingProgram) ? "selected" : "" %>>Diploma (6 Months)</option>
                        <option value="Graduate (3 Years)" <%= "Graduate (3 Years)".equals(trainingProgram) ? "selected" : "" %>>Graduate (3 Years)</option>
                        <option value="Graduate (4 Years)" <%= "Graduate (4 Years)".equals(trainingProgram) ? "selected" : "" %>>Graduate (4 Years)</option>
                        <option value="Postgraduate" <%= "Postgraduate".equals(trainingProgram) ? "selected" : "" %>>Postgraduate</option>
                    </select>
                    <span class="error-message"></span>
                </div>
                <div class="form-group" id="training_period_div" style="display: none;">
                    <label>12. Training Period:</label>
                    <select id="training_period" name="training_period" onchange="updateHiddenPeriod()" required>
                        <option value="">Select Training Period</option>
                    </select>
                    <input type="hidden" id="hidden_training_period" name="training_period" value="<%= trainingPeriod %>">
                    <span class="error-message"></span>
                </div>
                <div class="form-group read-only">
                    <label>Training Fee (Non-editable):</label>
                    <span>₹<%= String.format("%.2f", trainingFee) %></span>
                </div>
                <div class="form-group">
                    <label>13. Sub Caste:</label>
                    <input type="text" name="sub_caste" value="<%= subCaste != null ? subCaste : "" %>" required>
                </div>
                <div class="form-group">
                    <label>14. Mail ID:</label>
                    <input type="email" name="email" value="<%= email != null ? email : "" %>" required>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>15. Gender:</label>
                    <select name="gender" required>
                        <option value="">Select Gender</option>
                        <option value="Male" <%= "Male".equals(gender) ? "selected" : "" %>>Male</option>
                        <option value="Female" <%= "Female".equals(gender) ? "selected" : "" %>>Female</option>
                        <option value="Other" <%= "Other".equals(gender) ? "selected" : "" %>>Other</option>
                    </select>
                    <span class="error-message"></span>
                </div>
                <button type="submit" class="btn cta-btn">Update Application</button>
            </form>
                    <br>
            <a href="traineeDashboard.jsp" class="btn secondary-cta-btn">Back to Dashboard</a>
        </div>
        <%
            } catch (SQLException e) {
                e.printStackTrace();
        %>
        <div class="alert alert-error">
            <p>Error accessing the database. Please try again later.</p>
            <p><a href="traineeDashboard.jsp" class="btn secondary-cta-btn">Back to Dashboard</a></p>
        </div>
        <%
            } catch (Exception e) {
                e.printStackTrace();
        %>
        <div class="alert alert-error">
            <p>An unexpected error occurred. Please try again later.</p>
            <p><a href="traineeDashboard.jsp" class="btn secondary-cta-btn">Back to Dashboard</a></p>
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