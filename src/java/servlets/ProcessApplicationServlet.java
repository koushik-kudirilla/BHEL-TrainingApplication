package servlets;

import java.io.IOException;
import java.net.URLEncoder;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import utils.DBConnection;

@WebServlet("/ProcessApplicationServlet")
public class ProcessApplicationServlet extends HttpServlet {
    // Validation methods (unchanged)
    private boolean validateTextInput(String value, int minLength) {
        if (value == null) return false;
        String regex = "^[A-Za-z\\s]+$";
        return value.length() >= minLength && value.matches(regex);
    }

    private boolean validateDateOfBirth(String value) {
        if (value == null) return false;
        try {
            LocalDate dob = LocalDate.parse(value);
            LocalDate today = LocalDate.now();
            int age = today.getYear() - dob.getYear();
            if (dob.getMonthValue() > today.getMonthValue() || 
                (dob.getMonthValue() == today.getMonthValue() && dob.getDayOfMonth() > today.getDayOfMonth())) {
                age--;
            }
            return age >= 15 && !dob.isAfter(today);
        } catch (DateTimeParseException e) {
            return false;
        }
    }

    private boolean validatePhoneNumber(String value) {
        if (value == null) return false;
        String regex = "^\\d{10}$";
        return value.matches(regex);
    }

    private boolean validateAadhaar(String value) {
        if (value == null) return false;
        String regex = "^\\d{12}$";
        return value.matches(regex);
    }

    private boolean validateEmail(String value) {
        if (value == null) return false;
        String regex = "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$";
        return value.matches(regex);
    }

    private boolean validateAddress(String value) {
        if (value == null) return false;
        return value.length() >= 10;
    }

    private boolean validateDropdown(String value) {
        return value != null && !value.trim().isEmpty();
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        String username = (String) session.getAttribute("username");
        String role = (String) session.getAttribute("role");

        // Debug: Log session details
        System.out.println("Servlet - username: " + username + ", role: " + role);

        // Retrieve form parameters
        Integer userId = null;
        String userIdParam = request.getParameter("user_id");
        if (userIdParam != null && !userIdParam.trim().isEmpty()) {
            try {
                userId = Integer.parseInt(userIdParam);
            } catch (NumberFormatException e) {
                System.out.println("Servlet - Invalid user ID format: " + userIdParam);
                response.sendRedirect("applicationForm.jsp?error=Invalid+user+ID+format");
                return;
            }
        }

        // Validate user session and role
        if (username != null && "Trainee".equals(role) && userId == null) {
            System.out.println("Servlet - Missing user ID for Trainee");
            response.sendRedirect("applicationForm.jsp?error=Missing+user+ID+for+Trainee");
            return;
        }

        // Retrieve form data
        String applicantName = request.getParameter("applicant_name");
        String instituteName = request.getParameter("institute_name");
        String trade = request.getParameter("trade");
        String rollNo = request.getParameter("roll_no");
        String batch = request.getParameter("batch");
        String yearOfStudy = request.getParameter("year_of_study");
        String dob = request.getParameter("dob");
        String guardianName = request.getParameter("guardian_name");
        String address = request.getParameter("address");
        String contactNumber = request.getParameter("contact_number");
        String aadhaarNumber = request.getParameter("aadhaar_number");
        String trainingRequired = request.getParameter("training_required");
        String trainingProgram = request.getParameter("training_program");
        String[] trainingPeriodValues = request.getParameterValues("training_period");
        String trainingPeriod = null;
        if (trainingPeriodValues != null && trainingPeriodValues.length > 0) {
            for (String val : trainingPeriodValues) {
                if (val != null && !val.trim().isEmpty()) {
                    trainingPeriod = val;
                }
            }
        }
        String subCaste = request.getParameter("sub_caste");
        String email = request.getParameter("email");
        String gender = request.getParameter("gender");
        String soDo = request.getParameter("so_do");

        // Debug: Log form data
        System.out.println("Servlet - Form data: applicantName=" + applicantName + ", trainingProgram=" + trainingProgram + ", trainingPeriod=" + trainingPeriod);

        // Validate fields
        StringBuilder errorMessage = new StringBuilder();
        if (!validateTextInput(applicantName, 4)) {
            errorMessage.append("Applicant name must be at least 4 alphabetic characters,");
        }
        if (!validateTextInput(instituteName, 4)) {
            errorMessage.append("Institute name must be at least 4 alphabetic characters,");
        }
        if (!validateTextInput(trade, 4)) {
            errorMessage.append("Trade must be at least 4 alphabetic characters (e.g., Mechanical),");
        }
        if (rollNo == null || rollNo.trim().isEmpty()) {
            errorMessage.append("Roll number is required,");
        }
        if (batch == null || batch.trim().isEmpty()) {
            errorMessage.append("Batch is required,");
        }
        if (!validateDropdown(yearOfStudy)) {
            errorMessage.append("Year of study must be selected,");
        }
        if (!validateDateOfBirth(dob)) {
            errorMessage.append("Date of birth must be a valid date and applicant must be at least 15 years old,");
        }
        if (!validateTextInput(guardianName, 4)) {
            errorMessage.append("Guardian name must be at least 4 alphabetic characters,");
        }
        if (soDo != null && !soDo.trim().isEmpty() && !validateTextInput(soDo, 4)) {
            errorMessage.append("S/o, D/o, or C/o must be at least 4 alphabetic characters if provided,");
        }
        if (!validateAddress(address)) {
            errorMessage.append("Address must be at least 10 characters,");
        }
        if (!validatePhoneNumber(contactNumber)) {
            errorMessage.append("Contact number must be exactly 10 digits,");
        }
        if (!validateAadhaar(aadhaarNumber)) {
            errorMessage.append("Aadhaar number must be exactly 12 digits,");
        }
        if (!validateDropdown(trainingRequired)) {
            errorMessage.append("Training required must be selected,");
        }
        if (!validateDropdown(trainingProgram)) {
            errorMessage.append("Training program must be selected,");
        }
        if (!validateDropdown(trainingPeriod)) {
            errorMessage.append("Training period must be selected,");
        }
        if (subCaste == null || subCaste.trim().isEmpty()) {
            errorMessage.append("Sub caste is required,");
        }
        if (!validateEmail(email)) {
            errorMessage.append("Email must be a valid email address,");
        }
        if (!validateDropdown(gender)) {
            errorMessage.append("Gender must be selected,");
        }

        if (errorMessage.length() > 0) {
            String errorMsg = errorMessage.toString();
            if (errorMsg.endsWith(",")) {
                errorMsg = errorMsg.substring(0, errorMsg.length() - 1);
            }
            System.out.println("Servlet - Validation errors: " + errorMsg);
            response.sendRedirect("applicationForm.jsp?error=" + URLEncoder.encode(errorMsg, "UTF-8"));
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        double trainingFee = 0.0;
        Integer scheduleId = null;
        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            // Fetch training fee based on training program and period
            String feeTable = "";
            if ("Diploma (6 Months)".equals(trainingProgram)) {
                feeTable = "Diploma6Months";
            } else if ("Graduate (3 Years)".equals(trainingProgram)) {
                feeTable = "Graduate3Years";
            } else if ("Graduate (4 Years)".equals(trainingProgram)) {
                feeTable = "Graduate4Years";
            } else if ("Postgraduate".equals(trainingProgram)) {
                feeTable = "Postgraduate";
            }

            if (!feeTable.isEmpty()) {
                String feeSql = "SELECT Total FROM " + feeTable + " WHERE Duration = ?";
                pstmt = conn.prepareStatement(feeSql);
                pstmt.setString(1, trainingPeriod);
                rs = pstmt.executeQuery();
                if (rs.next()) {
                    trainingFee = rs.getDouble("Total");
                } else {
                    System.out.println("Servlet - Invalid training period: " + trainingPeriod + " for program: " + trainingProgram);
                    response.sendRedirect("applicationForm.jsp?error=Invalid+training+period+for+selected+program");
                    return;
                }
            } else {
                System.out.println("Servlet - Invalid training program: " + trainingProgram);
                response.sendRedirect("applicationForm.jsp?error=Invalid+training+program");
                return;
            }

            // Insert application into the database
            String sql = "INSERT INTO bhel_training_application (user_id, applicant_name, institute_name, trade, roll_no, batch, year_of_study, dob, guardian_name, address, contact_number, aadhaar_number, training_required, training_program, training_period, training_fee, sub_caste, email, gender, status, so_do, applied_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?)";
            pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            pstmt.setObject(1, userId, Types.INTEGER);
            pstmt.setString(2, applicantName);
            pstmt.setString(3, instituteName);
            pstmt.setString(4, trade);
            pstmt.setString(5, rollNo);
            pstmt.setString(6, batch);
            pstmt.setString(7, yearOfStudy);
            pstmt.setString(8, dob);
            pstmt.setString(9, guardianName);
            pstmt.setString(10, address);
            pstmt.setString(11, contactNumber);
            pstmt.setString(12, aadhaarNumber);
            pstmt.setString(13, trainingRequired);
            pstmt.setString(14, trainingProgram);
            pstmt.setString(15, trainingPeriod);
            pstmt.setDouble(16, trainingFee);
            pstmt.setString(17, subCaste);
            pstmt.setString(18, email);
            pstmt.setString(19, gender);
            pstmt.setString(20, soDo != null && !soDo.trim().isEmpty() ? soDo : null);
            pstmt.setDate(21, Date.valueOf(LocalDate.now()));
            pstmt.executeUpdate();

            rs = pstmt.getGeneratedKeys();
            int applicationId = 0;
            if (rs.next()) {
                applicationId = rs.getInt(1);
            }

            // Find a matching schedule (active or upcoming)
            sql = "SELECT id, capacity, (SELECT COUNT(*) FROM trainee_schedules WHERE schedule_id = training_schedules.id) as current_count " +
                  "FROM training_schedules WHERE training_type = ? AND (start_date >= CURDATE() OR (start_date <= CURDATE() AND end_date >= CURDATE())) LIMIT 1";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, trainingRequired);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                int capacity = rs.getInt("capacity");
                int currentCount = rs.getInt("current_count");
                if (currentCount < capacity) {
                    scheduleId = rs.getInt("id");
                }
            }

            // Assign the application to the schedule
            if (scheduleId != null) {
                sql = "INSERT INTO trainee_schedules (application_id, schedule_id, progress) VALUES (?, ?, 'Not Started')";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, applicationId);
                pstmt.setInt(2, scheduleId);
                pstmt.executeUpdate();
            }

            conn.commit();

            // Debug: Log success
            String debugInfo = "Servlet Debug: Success<br>" +
                "success: Application submitted successfully!<br>" +
                "trainingFee: " + String.format("%.2f", trainingFee) + "<br>" +
                "scheduleAssigned: " + (scheduleId != null ? "You have been assigned to a training schedule." : "Your application is pending schedule assignment.") + "<br>" +
                "username: " + (username != null ? username : "null") + "<br>" +
                "role: " + (role != null ? role : "null") + "<br>" +
                "userId: " + (userId != null ? userId : "null");
            System.out.println(debugInfo.replace("<br>", " | "));

            // Redirect with success parameters
            String redirectUrl = "applicationForm.jsp?success=Application+submitted+successfully!" +
                "&trainingFee=" + String.format("%.2f", trainingFee) +
                (scheduleId != null ? "&scheduleAssigned=You+have+been+assigned+to+a+training+schedule." : "&scheduleAssigned=Your+application+is+pending+schedule+assignment.") +
                "&servletDebug=" + URLEncoder.encode(debugInfo, "UTF-8");
            System.out.println("Servlet - Redirecting to: " + redirectUrl);
            response.sendRedirect(redirectUrl);

        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    System.out.println("Servlet - Rollback failed: " + ex.getMessage());
                }
            }
            System.out.println("Servlet - SQLException: SQLState=" + e.getSQLState() + ", ErrorCode=" + e.getErrorCode() + ", Message=" + e.getMessage());
            String errorMsg = "Database error";
            if (e.getSQLState().equals("23000") && e.getErrorCode() == 1452) {
                errorMsg = "Invalid user ID or schedule not found";
            } else if (e.getSQLState().equals("42S02")) {
                errorMsg = "Database table missing";
            }
            response.sendRedirect("applicationForm.jsp?error=" + URLEncoder.encode(errorMsg, "UTF-8"));
        } catch (Exception e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    System.out.println("Servlet - Rollback failed: " + ex.getMessage());
                }
            }
            System.out.println("Servlet - Unexpected error: " + e.getMessage());
            response.sendRedirect("applicationForm.jsp?error=Unexpected+error");
        } finally {
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException ignored) {}
            }
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException ignored) {}
            }
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ignored) {}
            }
        }
    }
}