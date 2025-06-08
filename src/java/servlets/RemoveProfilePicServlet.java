/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/JSP_Servlet/Servlet.java to edit this template
 */
package servlets;
import java.io.*;
import java.sql.*;
import javax.naming.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.util.logging.*;
import utils.DBConnection;

@WebServlet("/RemoveProfilePicServlet")
public class RemoveProfilePicServlet extends HttpServlet {
    private static final Logger LOGGER = Logger.getLogger(RemoveProfilePicServlet.class.getName());

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.getWriter().write("{\"success\": false, \"error\": \"User not logged in.\"}");
            return;
        }

        String username = (String) session.getAttribute("username");
        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false); // Start transaction

            String sql = "UPDATE users SET profile_pic = NULL WHERE username = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, username);
            pstmt.executeUpdate();

            conn.commit(); // Commit transaction
            LOGGER.info("Profile picture removed for user: " + username);
            response.getWriter().write("{\"success\": true}");

        } catch (NamingException e) {
            LOGGER.severe("NamingException: " + e.getMessage());
            response.getWriter().write("{\"success\": false, \"error\": \"Server configuration error: Unable to connect to database.\"}");
        } catch (SQLException e) {
            try { if (conn != null) conn.rollback(); } catch (SQLException ex) {}
            LOGGER.severe("SQLException: " + e.getMessage());
            response.getWriter().write("{\"success\": false, \"error\": \"Database error: " + e.getMessage() + "\"}");
        } finally {
            try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
            try { if (conn != null) { conn.setAutoCommit(true); conn.close(); } } catch (SQLException e) {}
        }
    }
}