<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="utils.DBConnection, java.sql.*, java.time.LocalDate, java.time.format.DateTimeFormatter, java.util.Arrays" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Schedule - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    <style>
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
        .reset-date-btn {
            background: linear-gradient(135deg, #4a5568, #cbd5e0);
            display: none;
        }
        .reset-date-btn.visible {
            display: inline-block;
        }
    </style>
    <script>
        const touchedFields = new Set();
        let calculatedEndDate = '';

        function validateDropdown(value, name) {
            if (name === "training_period") {
                const validValues = ["1 month", "2 months", "3 months", "4 months", "5 months", "6 months"];
                return validValues.includes(value);
            }
            return value !== "" && value !== "Select Training Type" && value !== "Select Training Period" && value !== "Select Trainer";
        }

        function validateDate(value) {
            const date = new Date(value);
            return date instanceof Date && !isNaN(date);
        }

        function validateEndDate(startDate, endDate) {
            const start = new Date(startDate);
            const end = new Date(endDate);
            return end >= start;
        }

        function validateCapacity(value) {
            return value > 0;
        }

        function toggleError(inputElement, message, isValid) {
            let errorElement = inputElement.nextElementSibling;
            if (!errorElement || !errorElement.classList.contains('error-message')) {
                errorElement = document.createElement('span');
                errorElement.className = 'error-message';
                inputElement.parentNode.insertBefore(errorElement, inputElement.nextSibling);
            }
            errorElement.innerText = message;
            errorElement.classList.toggle('active', !isValid && message !== '');
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
                case 'training_type':
                case 'trainer_id':
                    isValid = validateDropdown(value, name);
                    errorMessage = 'Please select an option.';
                    break;
                case 'training_period':
                    isValid = validateDropdown(value, name) || document.getElementById("training_type").value === "Diploma (6 Months)";
                    errorMessage = 'Please select a valid training period.';
                    break;
                case 'start_date':
                    isValid = validateDate(value);
                    errorMessage = 'Must be a valid date.';
                    break;
                case 'end_date':
                    const startDate = document.forms["editForm"]["start_date"].value;
                    isValid = validateDate(value) && validateEndDate(startDate, value);
                    errorMessage = 'Must be a valid date on or after the start date.';
                    break;
                case 'capacity':
                    isValid = validateCapacity(value);
                    errorMessage = 'Must be a positive number.';
                    break;
            }

            toggleError(inputElement, errorMessage, isValid);
        }

        function initializeValidation() {
            const inputs = document.querySelectorAll('input:not([type="hidden"])');
            const selects = document.querySelectorAll('select');
            inputs.forEach(input => {
                input.addEventListener('input', () => {
                    touchedFields.add(input);
                    validateInput(input);
                    if (input.name === 'start_date') {
                        updateEndDate();
                    } else if (input.name === 'end_date') {
                        toggleResetDateButton();
                    }
                });
                input.addEventListener('blur', () => {
                    touchedFields.add(input);
                    validateInput(input, true);
                });
            });
            selects.forEach(select => {
                select.addEventListener('change', () => {
                    touchedFields.add(select);
                    validateInput(select, true);
                    if (select.name === 'training_type' || select.name === 'training_period') {
                        updateTrainingPeriod();
                        updateEndDate();
                    }
                });
            });

            const resetDateBtn = document.getElementById('reset-date-btn');
            if (resetDateBtn) {
                resetDateBtn.addEventListener('click', () => {
                    const endDateInput = document.forms["editForm"]["end_date"];
                    endDateInput.value = calculatedEndDate;
                    validateInput(endDateInput, true);
                    toggleResetDateButton();
                });
            }
        }

        function updateTrainingPeriod() {
            const trainingType = document.getElementById("training_type").value;
            const periodDiv = document.getElementById("training_period_div");
            const periodSelect = document.getElementById("training_period");
            const currentValue = periodSelect.value;

            if (trainingType === "Diploma (6 Months)") {
                periodDiv.style.display = "none";
                periodSelect.value = "6 months";
                periodSelect.disabled = true;
            } else if (["Graduate (3 Years)", "Graduate (4 Years)", "Postgraduate"].includes(trainingType)) {
                periodDiv.style.display = "block";
                periodSelect.disabled = false;
                periodSelect.innerHTML = "";
                const options = ["", "1 month", "2 months", "3 months", "4 months", "5 months", "6 months"];
                options.forEach(optionValue => {
                    const option = document.createElement("option");
                    option.value = optionValue;
                    option.text = optionValue || "Select Training Period";
                    periodSelect.appendChild(option);
                });
                periodSelect.value = currentValue && options.includes(currentValue) ? currentValue : "";
            } else {
                periodDiv.style.display = "none";
                periodSelect.value = "";
                periodSelect.disabled = true;
            }
            validateInput(periodSelect, touchedFields.has(periodSelect));
            updateEndDate();
        }

        function updateEndDate() {
            const startDateInput = document.forms["editForm"]["start_date"];
            const trainingPeriod = document.forms["editForm"]["training_period"].value;
            const endDateInput = document.forms["editForm"]["end_date"];
            const trainingType = document.getElementById("training_type").value;

            if (startDateInput.value && (trainingPeriod || trainingType === "Diploma (6 Months)") && validateDate(startDateInput.value)) {
                const startDate = new Date(startDateInput.value);
                const months = trainingType === "Diploma (6 Months)" ? 6 : parseInt(trainingPeriod) || 0;
                const endDate = new Date(startDate);
                endDate.setMonth(startDate.getMonth() + months);
                endDate.setDate(endDate.getDate() - 1);
                calculatedEndDate = endDate.toISOString().split('T')[0];
                endDateInput.value = calculatedEndDate;
            } else {
                calculatedEndDate = '';
                if (!endDateInput.value) {
                    endDateInput.value = '';
                }
            }
            validateInput(endDateInput, touchedFields.has(endDateInput));
            toggleResetDateButton();
        }

        function toggleResetDateButton() {
            const endDateInput = document.forms["editForm"]["end_date"];
            const resetDateBtn = document.getElementById('reset-date-btn');
            if (resetDateBtn) {
                resetDateBtn.classList.toggle('visible', calculatedEndDate !== '' && endDateInput.value !== calculatedEndDate);
            }
        }

        function validateForm() {
            const inputs = document.querySelectorAll('input:not([type="hidden"]), select:not([name="training_period"])');
            let isValid = true;
            inputs.forEach(input => {
                validateInput(input, true);
                if (input.nextElementSibling.classList.contains('active')) {
                    isValid = false;
                }
            });
            const trainingType = document.getElementById("training_type").value;
            if (trainingType !== "Diploma (6 Months)") {
                const periodSelect = document.getElementById("training_period");
                validateInput(periodSelect, true);
                if (periodSelect.nextElementSibling.classList.contains('active')) {
                    isValid = false;
                }
            }
            const submitButton = document.querySelector('button[type="submit"]');
            submitButton.disabled = !isValid;
            submitButton.innerText = isValid ? 'Updating...' : 'Update Schedule';
            return isValid;
        }

        window.onload = function() {
            initializeValidation();
            updateTrainingPeriod();
            updateEndDate();
        };
    </script>
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="container">
        <div class="hero">
            <div class="hero-content">
                <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
                <h1>Edit Training Schedule - BHEL HRDC</h1>
            </div>
        </div>
        <%
            String username = (String) session.getAttribute("username");
            String role = (String) session.getAttribute("role");
            if (username == null || role == null || !role.equals("Admin")) {
                response.sendRedirect("traineeLogin.jsp?error=Unauthorized access");
                return;
            }

            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            int scheduleId = Integer.parseInt(request.getParameter("scheduleId"));
            String errorMessage = null;

            try {
                conn = DBConnection.getConnection();
                LocalDate today = LocalDate.now();
                DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");

                // Handle schedule update
                if ("POST".equalsIgnoreCase(request.getMethod())) {
                    String trainingType = request.getParameter("training_type");
                    String trainingPeriod = request.getParameter("training_period");
                    String startDate = request.getParameter("start_date");
                    String endDate = request.getParameter("end_date");
                    String capacity = request.getParameter("capacity");
                    String trainerId = request.getParameter("trainer_id");

                    String[] validTrainingTypes = {"Diploma (6 Months)", "Graduate (3 Years)", "Graduate (4 Years)", "Postgraduate"};
                    String[] validTrainingPeriods = {"1 month", "2 months", "3 months", "4 months", "5 months", "6 months"};

                    if (trainingType == null || startDate == null || endDate == null || capacity == null || trainerId == null) {
                        errorMessage = "Required fields are missing.";
                    } else if (!Arrays.asList(validTrainingTypes).contains(trainingType)) {
                        errorMessage = "Invalid training type.";
                    } else if (!trainingType.equals("Diploma (6 Months)") && (trainingPeriod == null || !Arrays.asList(validTrainingPeriods).contains(trainingPeriod))) {
                        errorMessage = "Invalid or missing training period.";
                    } else {
                        LocalDate start = LocalDate.parse(startDate);
                        LocalDate end = LocalDate.parse(endDate);
                        int capacityValue = Integer.parseInt(capacity);
                        if (end.isBefore(start)) {
                            errorMessage = "End date must be on or after the start date.";
                        } else if (capacityValue <= 0) {
                            errorMessage = "Capacity must be a positive number.";
                        } else {
                            String sql = "UPDATE training_schedules SET training_type = ?, training_period = ?, start_date = ?, end_date = ?, capacity = ?, trainer_id = ? WHERE id = ?";
                            pstmt = conn.prepareStatement(sql);
                            pstmt.setString(1, trainingType);
                            pstmt.setString(2, trainingType.equals("Diploma (6 Months)") ? "6 months" : trainingPeriod);
                            pstmt.setString(3, startDate);
                            pstmt.setString(4, endDate);
                            pstmt.setInt(5, capacityValue);
                            pstmt.setInt(6, Integer.parseInt(trainerId));
                            pstmt.setInt(7, scheduleId);
                            int rows = pstmt.executeUpdate();
                            if (rows > 0) {
                                session.setAttribute("successMessage", "Schedule updated successfully!");
                                response.sendRedirect("manageSchedules.jsp");
                                return;
                            } else {
                                errorMessage = "Failed to update schedule.";
                            }
                        }
                    }
                }

                // Fetch current schedule details if no success message
                if (errorMessage != null) {
        %>
        <div class="alert alert-error">
            <p><%= errorMessage %></p>
        </div>
        <%
                }
                String sql = "SELECT s.training_type, s.training_period, s.start_date, s.end_date, s.capacity, s.trainer_id, u.username as trainer " +
                             "FROM training_schedules s JOIN users u ON s.trainer_id = u.id WHERE s.id = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, scheduleId);
                rs = pstmt.executeQuery();

                if (rs.next()) {
                    String trainingType = rs.getString("training_type");
                    String trainingPeriod = rs.getString("training_period");
                    String startDate = rs.getString("start_date");
                    String endDate = rs.getString("end_date");
                    int capacity = rs.getInt("capacity");
                    int trainerId = rs.getInt("trainer_id");
                    String trainerUsername = rs.getString("trainer");
        %>
        <div class="content">
            <h2>Edit Schedule</h2>
            <form name="editForm" action="editSchedule.jsp?scheduleId=<%= scheduleId %>" method="post" onsubmit="return validateForm()">
                <div class="form-group">
                    <label>Training Type:</label>
                    <select id="training_type" name="training_type" required>
                        <option value="">Select Training Type</option>
                        <option value="Diploma (6 Months)" <%= trainingType.equals("Diploma (6 Months)") ? "selected" : "" %>>Diploma (6 Months)</option>
                        <option value="Graduate (3 Years)" <%= trainingType.equals("Graduate (3 Years)") ? "selected" : "" %>>Graduate (3 Years)</option>
                        <option value="Graduate (4 Years)" <%= trainingType.equals("Graduate (4 Years)") ? "selected" : "" %>>Graduate (4 Years)</option>
                        <option value="Postgraduate" <%= trainingType.equals("Postgraduate") ? "selected" : "" %>>Postgraduate</option>
                    </select>
                    <span class="error-message"></span>
                </div>
                <div class="form-group" id="training_period_div" style="display: <%= trainingType.equals("Diploma (6 Months)") ? "none" : "block" %>;">
                    <label>Training Period:</label>
                    <select id="training_period" name="training_period" <%= trainingType.equals("Diploma (6 Months)") ? "disabled" : "" %>>
                        <option value="">Select Training Period</option>
                        <option value="1 month" <%= trainingPeriod.equals("1 month") ? "selected" : "" %>>1 month</option>
                        <option value="2 months" <%= trainingPeriod.equals("2 months") ? "selected" : "" %>>2 months</option>
                        <option value="3 months" <%= trainingPeriod.equals("3 months") ? "selected" : "" %>>3 months</option>
                        <option value="4 months" <%= trainingPeriod.equals("4 months") ? "selected" : "" %>>4 months</option>
                        <option value="5 months" <%= trainingPeriod.equals("5 months") ? "selected" : "" %>>5 months</option>
                        <option value="6 months" <%= trainingPeriod.equals("6 months") ? "selected" : "" %>>6 months</option>
                    </select>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>Start Date:</label>
                    <input type="date" name="start_date" value="<%= startDate %>" required>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>End Date:</label>
                    <input type="date" name="end_date" value="<%= endDate %>" required>
                    <br>
                    <br>
                    <button type="button" id="reset-date-btn" class="btn reset-date-btn">Reset Date</button>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>Capacity:</label>
                    <input type="number" name="capacity" value="<%= capacity %>" min="1" required>
                    <span class="error-message"></span>
                </div>
                <div class="form-group">
                    <label>Assign Trainer:</label>
                    <select name="trainer_id" required>
                        <option value="">Select Trainer</option>
                        <%
                            try (PreparedStatement trainerStmt = conn.prepareStatement("SELECT id, username FROM users WHERE role = 'Trainer'");
                                 ResultSet trainerRs = trainerStmt.executeQuery()) {
                                while (trainerRs.next()) {
                                    int tId = trainerRs.getInt("id");
                                    String tUsername = trainerRs.getString("username");
                        %>
                        <option value="<%= tId %>" <%= tId == trainerId ? "selected" : "" %>><%= tUsername %></option>
                        <%
                                }
                            }
                        %>
                    </select>
                    <span class="error-message"></span>
                </div>
                <button type="submit" class="btn cta-btn">Update Schedule</button>
                <a href="manageSchedules.jsp" class="btn secondary-cta-btn">Cancel</a>
            </form>
        </div>
        <%
                } else {
        %>
        <div class="alert alert-error">
            <p>Schedule not found.</p>
        </div>
        <%
                }
        %>
        <br/>
        <a href="manageSchedules.jsp" class="btn secondary-cta-btn">Back</a>
    </div>
    <jsp:include page="footer.jsp" />
    <%
        } catch (SQLException e) {
    %>
    <div class="alert alert-error">
        <p>Error: Unable to load schedule. Please try again later.</p>
    </div>
    <%
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
        }
    %>
</body>
</html>