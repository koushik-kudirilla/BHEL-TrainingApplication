package servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.nio.file.Paths;
import java.sql.*;
import java.util.UUID;
import utils.DBConnection;

@WebServlet("/UploadDocumentsServlet")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,  // 1MB
    maxFileSize = 1024 * 1024 * 5,    // 5MB per file
    maxRequestSize = 1024 * 1024 * 20 // 20MB total
)
public class UploadDocumentsServlet extends HttpServlet {

    private static final String UPLOAD_DIR = "uploads";
    private static final String DB_URL = "jdbc:mysql://localhost:3306/trainingDB";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "9392148628@abcd";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        String username = (session != null) ? (String) session.getAttribute("username") : null;
        String role = (session != null) ? (String) session.getAttribute("role") : null;

        if (username == null || role == null || !"Trainee".equals(role)) {
            response.sendRedirect("traineeLogin.jsp");
            return;
        }

        String instituteLetterPath = null;
        String aadhaarPath = null;
        String photoPath = null;
        String collegeIdPath = null;

        Connection conn = null;
        try {
          //  Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DBConnection.getConnection();

            // Fetch latest application ID for user and check status
            int applicationId = -1;
            String status = null;
            String getAppSql = "SELECT id, status, institute_letter_path, aadhaar_path, photo_path, college_id_path " +
                              "FROM bhel_training_application " +
                              "WHERE user_id = (SELECT id FROM users WHERE username = ?) " +
                              "ORDER BY id DESC LIMIT 1";
            try (PreparedStatement stmt = conn.prepareStatement(getAppSql)) {
                stmt.setString(1, username);
                ResultSet rs = stmt.executeQuery();
                if (rs.next()) {
                    applicationId = rs.getInt("id");
                    status = rs.getString("status");

                    // Check if documents have already been uploaded
                    String existingInstituteLetterPath = rs.getString("institute_letter_path");
                    String existingAadhaarPath = rs.getString("aadhaar_path");
                    String existingPhotoPath = rs.getString("photo_path");
                    String existingCollegeIdPath = rs.getString("college_id_path");

                    if (existingInstituteLetterPath != null || existingAadhaarPath != null || 
                        existingPhotoPath != null || existingCollegeIdPath != null) {
                        request.setAttribute("message", "Documents have already been uploaded for this application.");
                        request.getRequestDispatcher("uploadDocuments.jsp").forward(request, response);
                        return;
                    }

                    // Check if application status is Approved or Rejected
                    if ("Approved".equals(status) || "Rejected".equals(status)) {
                        request.setAttribute("message", "Cannot upload documents for an application that is already " + status.toLowerCase() + ".");
                        request.getRequestDispatcher("uploadDocuments.jsp").forward(request, response);
                        return;
                    }
                } else {
                    request.setAttribute("message", "No application found. Please submit an application first.");
                    request.getRequestDispatcher("uploadDocuments.jsp").forward(request, response);
                    return;
                }
            }

            // Use project uploads directory for file storage
            String uploadPath = getServletContext().getRealPath("/" + UPLOAD_DIR);
            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }

            // Process each file upload
            for (Part part : request.getParts()) {
                String fieldName = part.getName();
                String fileName = Paths.get(part.getSubmittedFileName()).getFileName().toString();

                if (fileName == null || fileName.isEmpty()) continue;

                String extension = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
                boolean isValidExtension = false;

                // Validate file extensions based on field
                if ("photo".equals(fieldName)) {
                    isValidExtension = extension.equals("jpg") || extension.equals("jpeg");
                } else {
                    isValidExtension = extension.equals("pdf") || extension.equals("jpg") || extension.equals("jpeg");
                }

                if (!isValidExtension) {
                    request.setAttribute("message", "Invalid file format for " + fieldName + ". Allowed formats: " + 
                        ("photo".equals(fieldName) ? "JPG/JPEG" : "PDF/JPG/JPEG"));
                    request.getRequestDispatcher("uploadDocuments.jsp").forward(request, response);
                    return;
                }

                String newFileName = username + "_" + UUID.randomUUID() + "_" + fileName;
                String filePath = uploadPath + File.separator + newFileName;

                try (InputStream fileContent = part.getInputStream(); FileOutputStream fos = new FileOutputStream(filePath)) {
                    byte[] buffer = new byte[1024];
                    int bytesRead;
                    while ((bytesRead = fileContent.read(buffer)) != -1) {
                        fos.write(buffer, 0, bytesRead);
                    }
                }

                String relativePath = UPLOAD_DIR + "/" + newFileName;
                if ("institute_letter".equals(fieldName)) {
                    instituteLetterPath = relativePath;
                } else if ("aadhaar".equals(fieldName)) {
                    aadhaarPath = relativePath;
                } else if ("photo".equals(fieldName)) {
                    photoPath = relativePath;
                } else if ("college_id".equals(fieldName)) {
                    collegeIdPath = relativePath;
                }
            }

            // Validate that all required files were uploaded
            if (instituteLetterPath == null || aadhaarPath == null || photoPath == null || collegeIdPath == null) {
                request.setAttribute("message", "Please upload all required documents.");
                request.getRequestDispatcher("uploadDocuments.jsp").forward(request, response);
                return;
            }

            // Update DB with file paths
            String updateSql = "UPDATE bhel_training_application SET institute_letter_path = ?, aadhaar_path = ?, photo_path = ?, college_id_path = ? WHERE id = ?";
            try (PreparedStatement updateStmt = conn.prepareStatement(updateSql)) {
                updateStmt.setString(1, instituteLetterPath);
                updateStmt.setString(2, aadhaarPath);
                updateStmt.setString(3, photoPath);
                updateStmt.setString(4, collegeIdPath);
                updateStmt.setInt(5, applicationId);
                int rows = updateStmt.executeUpdate();

                if (rows > 0) {
                    request.setAttribute("message", "Documents uploaded successfully.");
                    request.setAttribute("uploadSuccess", true);
                } else {
                    request.setAttribute("message", "Failed to update database.");
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("message", "Server error: " + e.getMessage());
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException ignored) {}
            }
        }

        request.getRequestDispatcher("uploadDocuments.jsp").forward(request, response);
    }

    // Method to clean up files when application status changes to Approved or Rejected
    public void cleanupFilesForNonPendingStatus() {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            String sql = "SELECT institute_letter_path, aadhaar_path, photo_path, college_id_path " +
                         "FROM bhel_training_application WHERE status IN ('Approved', 'Rejected')";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                ResultSet rs = stmt.executeQuery();
                while (rs.next()) {
                    String[] paths = {
                        rs.getString("institute_letter_path"),
                        rs.getString("aadhaar_path"),
                        rs.getString("photo_path"),
                        rs.getString("college_id_path")
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
                String updateSql = "UPDATE bhel_training_application SET institute_letter_path = NULL, aadhaar_path = NULL, photo_path = NULL, college_id_path = NULL " +
                                  "WHERE status IN ('Approved', 'Rejected')";
                try (PreparedStatement updateStmt = conn.prepareStatement(updateSql)) {
                    updateStmt.executeUpdate();
                }
            }
        } catch (SQLException e) {
            System.err.println("Error during file cleanup: " + e.getMessage());
        }
    }
}