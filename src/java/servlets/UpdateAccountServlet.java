package servlets;
import java.io.*;
import java.sql.*;
import javax.naming.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.util.logging.*;
import utils.DBConnection;

@WebServlet("/UpdateAccountServlet")
@MultipartConfig(fileSizeThreshold = 1024 * 1024 * 2, // 2MB
                 maxFileSize = 1024 * 1024 * 10,      // 10MB
                 maxRequestSize = 1024 * 1024 * 50)   // 50MB
public class UpdateAccountServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(UpdateAccountServlet.class.getName());
    private static final String UPLOAD_DIR = "images";
    private static final String DEFAULT_PROFILE_PIC = "images/profile.png";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("text/html;charset=UTF-8");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendRedirect("traineeLogin.jsp");
            return;
        }

        String username = (String) session.getAttribute("username");
        String email = request.getParameter("email");
        Part filePart = request.getPart("profilePic");

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false); // Start transaction

            // Validate email
            if (email == null || email.trim().isEmpty()) {
                throw new Exception("Email is required.");
            }
            email = email.trim();

            // Check if email already exists for another user
            String checkEmailSql = "SELECT username FROM users WHERE email = ? AND username != ?";
            pstmt = conn.prepareStatement(checkEmailSql);
            pstmt.setString(1, email);
            pstmt.setString(2, username);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                throw new Exception("Email already exists.");
            }

            // Handle profile picture upload
            String profilePicPath = null;
            if (filePart != null && filePart.getSize() > 0) {
                String fileName = extractFileName(filePart);
                if (!fileName.endsWith(".jpg") && !fileName.endsWith(".jpeg") && !fileName.endsWith(".png")) {
                    throw new Exception("Only JPG, JPEG, and PNG files are allowed.");
                }
                String appPath = request.getServletContext().getRealPath("");
                String savePath = appPath + File.separator + UPLOAD_DIR;
                File fileSaveDir = new File(savePath);
                if (!fileSaveDir.exists()) {
                    fileSaveDir.mkdir();
                }
                profilePicPath = UPLOAD_DIR + File.separator + username + "_" + System.currentTimeMillis() + "_" + fileName;
                filePart.write(appPath + File.separator + profilePicPath);
            }

            // Update user in the database
            StringBuilder updateSql = new StringBuilder("UPDATE users SET email = ?");
            if (profilePicPath != null) {
                updateSql.append(", profile_pic = ?");
            }
            updateSql.append(" WHERE username = ?");
            
            pstmt = conn.prepareStatement(updateSql.toString());
            int paramIndex = 1;
            pstmt.setString(paramIndex++, email);
            if (profilePicPath != null) {
                pstmt.setString(paramIndex++, profilePicPath);
            }
            pstmt.setString(paramIndex, username);
            pstmt.executeUpdate();

            conn.commit(); // Commit transaction
            LOGGER.info("Account updated for user: " + username);
            response.sendRedirect("accountSettings.jsp?message=Account+updated+successfully");

        } catch (Exception e) {
            try { if (conn != null) conn.rollback(); } catch (SQLException ex) {}
            LOGGER.severe("Error updating account: " + e.getMessage());
            response.sendRedirect("accountSettings.jsp?error=" + e.getMessage().replace(" ", "+"));
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
            try { if (conn != null) { conn.setAutoCommit(true); conn.close(); } } catch (SQLException e) {}
        }
    }

    private String extractFileName(Part part) {
    String contentDisp = part.getHeader("content-disposition");
        String[] items = contentDisp.split(";");
        for (String s : items) {
            if (s.trim().startsWith("filename")) {
                return s.substring(s.indexOf("=") + 2, s.length() - 1);
            }
        }
        return "";
    }
}