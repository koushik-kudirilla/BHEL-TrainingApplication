package servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;
import java.net.URLEncoder;

@WebServlet("/UpdateApplicationServlet")
public class UpdateApplicationServlet extends HttpServlet {

    private static final String DB_URL = "jdbc:mysql://localhost:3306/trainingDB";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "YOUR PASSWORD";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Get the session, do not create a new one if it doesn't exist
        HttpSession session = request.getSession(false);

        // Check if session is null
        if (session == null) {
            System.out.println("Session is null - redirecting to login.jsp");
            response.sendRedirect("login.jsp?error=Session+expired+or+not+logged+in");
            return;
        }

        String username = (String) session.getAttribute("username");
        String role = (String) session.getAttribute("role");

        if (username == null || role == null || !"Trainee".equals(role)) {
            System.out.println("Invalid session attributes - username: " + username + ", role: " + role);
            response.sendRedirect("login.jsp?error=Not+authenticated+or+invalid+role");
            return;
        }

        // Retrieve form parameters using getParameter
        String appIdParam = request.getParameter("app_id");
        int appId;
        try {
            appId = Integer.parseInt(appIdParam);
        } catch (NumberFormatException e) {
            System.out.println("Invalid application ID format: " + appIdParam);
            response.sendRedirect("traineeDashboard.jsp?error=Invalid+application+ID+format");
            return;
        }

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
        String trainingPeriod = request.getParameter("training_period");
        String subCaste = request.getParameter("sub_caste");
        String email = request.getParameter("email");
        String gender = request.getParameter("gender");
        String soDo = request.getParameter("so_do");

        // Validate required fields
        if (applicantName == null || applicantName.trim().isEmpty() ||
            instituteName == null || instituteName.trim().isEmpty() ||
            trade == null || trade.trim().isEmpty() ||
            rollNo == null || rollNo.trim().isEmpty() ||
            batch == null || batch.trim().isEmpty() ||
            yearOfStudy == null || yearOfStudy.trim().isEmpty() ||
            dob == null || dob.trim().isEmpty() ||
            guardianName == null || guardianName.trim().isEmpty() ||
            address == null || address.trim().isEmpty() ||
            contactNumber == null || contactNumber.trim().isEmpty() ||
            aadhaarNumber == null || aadhaarNumber.trim().isEmpty() ||
            trainingRequired == null || trainingRequired.trim().isEmpty() ||
            trainingProgram == null || trainingProgram.trim().isEmpty() ||
            trainingPeriod == null || trainingPeriod.trim().isEmpty() ||
            subCaste == null || subCaste.trim().isEmpty() ||
            email == null || email.trim().isEmpty() ||
            gender == null || gender.trim().isEmpty()) {
            System.out.println("Missing required fields for application ID: " + appId);
            response.sendRedirect("editApplication.jsp?appId=" + appId + "&error=Missing+required+fields");
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
            conn.setAutoCommit(false);

            // Verify the application exists and is editable (status = 'pending')
            String sql = "SELECT user_id FROM bhel_training_application WHERE id = ? AND status = 'pending'";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, appId);
            rs = pstmt.executeQuery();
            if (!rs.next()) {
                System.out.println("Application not found or not editable for ID: " + appId);
                response.sendRedirect("traineeDashboard.jsp?error=Application+not+found+or+not+editable");
                return;
            }

            int userId = rs.getInt("user_id");
            rs.close();
            pstmt.close();

            // Verify the logged-in user owns the application
            sql = "SELECT id FROM users WHERE username = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();
            int sessionUserId = 0;
            if (rs.next()) {
                sessionUserId = rs.getInt("id");
            }
            rs.close();
            pstmt.close();

            if (userId != sessionUserId) {
                System.out.println("Unauthorized access attempt by user: " + username + " for application ID: " + appId);
                response.sendRedirect("traineeDashboard.jsp?error=Unauthorized+access+to+application");
                return;
            }

            // Determine training fee based on program and period
            double trainingFee = 0.0;
            String feeTable = "";
            if ("Diploma (6 Months)".equals(trainingProgram)) {
                feeTable = "Diploma6Months";
            } else if ("Graduate (3 Years)".equals(trainingProgram)) {
                feeTable = "Graduate3Years";
            } else if ("Graduate (4 Years)".equals(trainingProgram)) {
                feeTable = "Graduate4Years";
            } else if ("Postgraduate".equals(trainingProgram)) {
                feeTable = "PostGraduate";
            }

            if (!feeTable.isEmpty()) {
                String feeSql = "SELECT Total FROM " + feeTable + " WHERE Duration = ?";
                pstmt = conn.prepareStatement(feeSql);
                pstmt.setString(1, trainingPeriod);
                rs = pstmt.executeQuery();
                if (rs.next()) {
                    trainingFee = rs.getDouble("Total");
                } else {
                    System.out.println("Invalid training period for program: " + trainingProgram + ", period: " + trainingPeriod);
                    response.sendRedirect("editApplication.jsp?appId=" + appId + "&error=Invalid+training+period+for+selected+program");
                    return;
                }
                rs.close();
                pstmt.close();
            } else {
                System.out.println("Invalid training program: " + trainingProgram);
                response.sendRedirect("editApplication.jsp?appId=" + appId + "&error=Invalid+training+program");
                return;
            }

            // Update the application (no file paths updated since file uploads are handled separately)
            sql = "UPDATE bhel_training_application SET applicant_name = ?, institute_name = ?, trade = ?, roll_no = ?, batch = ?, year_of_study = ?, dob = ?, guardian_name = ?, address = ?, contact_number = ?, aadhaar_number = ?, training_required = ?, training_program = ?, training_period = ?, training_fee = ?, sub_caste = ?, email = ?, gender = ?, so_do = ? WHERE id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, applicantName);
            pstmt.setString(2, instituteName);
            pstmt.setString(3, trade);
            pstmt.setString(4, rollNo);
            pstmt.setString(5, batch);
            pstmt.setString(6, yearOfStudy);
            pstmt.setString(7, dob);
            pstmt.setString(8, guardianName);
            pstmt.setString(9, address);
            pstmt.setString(10, contactNumber);
            pstmt.setString(11, aadhaarNumber);
            pstmt.setString(12, trainingRequired);
            pstmt.setString(13, trainingProgram);
            pstmt.setString(14, trainingPeriod);
            pstmt.setDouble(15, trainingFee);
            pstmt.setString(16, subCaste);
            pstmt.setString(17, email);
            pstmt.setString(18, gender);
            pstmt.setString(19, soDo);
            pstmt.setInt(20, appId);
            int rows = pstmt.executeUpdate();

            if (rows > 0) {
                conn.commit();
                System.out.println("Application updated successfully for ID: " + appId + " by user: " + username);
                // Add timestamp to the success message and encode parameters
                long timestamp = System.currentTimeMillis();
                String encodedMessage = URLEncoder.encode("Application updated successfully", "UTF-8");
                String redirectUrl = "traineeDashboard.jsp?message=" + encodedMessage + "&timestamp=" + timestamp;
                response.sendRedirect(redirectUrl);
            } else {
                conn.rollback();
                System.out.println("Failed to update application for ID: " + appId);
                response.sendRedirect("editApplication.jsp?appId=" + appId + "&error=Failed+to+update+application");
            }
        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
            String errorMessage = "Database error: " + e.getMessage() + " (SQL State: " + e.getSQLState() + ", Error Code: " + e.getErrorCode() + ")";
            System.out.println("Database error while updating application ID: " + appId + " - " + errorMessage);
            response.sendRedirect("editApplication.jsp?appId=" + appId + "&error=" + URLEncoder.encode(errorMessage, "UTF-8"));
        } catch (Exception e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            e.printStackTrace();
            System.out.println("Server error while updating application ID: " + appId + " - " + e.getMessage());
            response.sendRedirect("editApplication.jsp?appId=" + appId + "&error=Server+error:+" + URLEncoder.encode(e.getMessage(), "UTF-8"));
        } finally {
            try {
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
                if (conn != null) {
                    conn.setAutoCommit(true);
                    conn.close();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    // Method to clean up files when application status changes to Approved or Rejected
    public void cleanupFilesForNonPendingStatus() {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            String sql = "SELECT aadhaar_path, institute_letter_path FROM bhel_training_application WHERE status IN ('Approved', 'Rejected')";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                ResultSet rs = stmt.executeQuery();
                while (rs.next()) {
                    String[] paths = {
                        rs.getString("aadhaar_path"),
                        rs.getString("institute_letter_path")
                    };
                    for (String path : paths) {
                        if (path != null && !path.isEmpty()) {
                            File file = new File(getServletContext().getRealPath("/") + File.separator + path);
                            if (file.exists() && file.delete()) {
                                System.out.println("Deleted file for finalized application: " + path);
                            } else if (file.exists()) {
                                System.err.println("Failed to delete file: " + path);
                            }
                        }
                    }
                }

                // Clear file paths in database for finalized applications
                String updateSql = "UPDATE bhel_training_application SET aadhaar_path = NULL, institute_letter_path = NULL WHERE status IN ('Approved', 'Rejected')";
                try (PreparedStatement updateStmt = conn.prepareStatement(updateSql)) {
                    updateStmt.executeUpdate();
                }
            }
        } catch (SQLException e) {
            System.err.println("Error during file cleanup: " + e.getMessage());
        }
    }
}