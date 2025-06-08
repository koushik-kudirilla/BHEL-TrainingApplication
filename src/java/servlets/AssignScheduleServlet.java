package servlets;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;

@WebServlet("/AssignScheduleServlet")
public class AssignScheduleServlet extends HttpServlet {

    private static final String DB_URL = "jdbc:mysql://localhost:3306/trainingDB";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "YOUR PASSWORD";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Check user session and role
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("role") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String role = (String) session.getAttribute("role");
        if (!"Admin".equals(role) && !"Trainer".equals(role)) {
            request.setAttribute("errorMessage", "Unauthorized access. Please log in as an Admin or Trainer.");
            response.sendRedirect("login.jsp");
            return;
        }

        // Get and validate parameters
        String appIdParam = request.getParameter("appId");
        String scheduleIdParam = request.getParameter("scheduleId");

        if (appIdParam == null || appIdParam.trim().isEmpty() || scheduleIdParam == null || scheduleIdParam.trim().isEmpty()) {
            request.setAttribute("error", "Invalid application or schedule ID.");
            response.sendRedirect("viewApplications.jsp");
            return;
        }

        int appId, scheduleId;
        try {
            appId = Integer.parseInt(appIdParam.trim());
            scheduleId = Integer.parseInt(scheduleIdParam.trim());
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid application or schedule ID format.");
            response.sendRedirect("viewApplications.jsp");
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            // Initialize database connection
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

            // Check if the application exists, is Approved, and has no schedule
            String checkSql = "SELECT a.status, ts.schedule_id " +
                             "FROM bhel_training_application a " +
                             "LEFT JOIN trainee_schedules ts ON a.id = ts.application_id " +
                             "WHERE a.id = ?";
            pstmt = conn.prepareStatement(checkSql);
            pstmt.setInt(1, appId);
            rs = pstmt.executeQuery();

            if (rs.next()) {
                String status = rs.getString("status");
                String existingScheduleId = rs.getString("schedule_id");

                if (!"Approved".equals(status)) {
                    request.setAttribute("error", "Application must be Approved to assign a schedule.");
                    response.sendRedirect("viewApplications.jsp");
                    return;
                }
                if (existingScheduleId != null) {
                    request.setAttribute("error", "A schedule is already assigned to this application.");
                    response.sendRedirect("viewApplications.jsp");
                    return;
                }
            } else {
                request.setAttribute("error", "Application not found.");
                response.sendRedirect("viewApplications.jsp");
                return;
            }

            // Check if the schedule exists and is valid
            String scheduleCheckSql = "SELECT id FROM training_schedules WHERE id = ?";
            pstmt = conn.prepareStatement(scheduleCheckSql);
            pstmt.setInt(1, scheduleId);
            rs = pstmt.executeQuery();

            if (!rs.next()) {
                request.setAttribute("error", "Selected schedule does not exist.");
                response.sendRedirect("viewApplications.jsp");
                return;
            }

            // Assign the schedule
            String insertSql = "INSERT INTO trainee_schedules (application_id, schedule_id, progress) VALUES (?, ?, ?)";
            pstmt = conn.prepareStatement(insertSql);
            pstmt.setInt(1, appId);
            pstmt.setInt(2, scheduleId);
            pstmt.setString(3, "Not Started");
            int rows = pstmt.executeUpdate();

            if (rows > 0) {
                request.setAttribute("message", "Schedule assigned successfully to application ID " + appId + ".");
            } else {
                request.setAttribute("error", "Failed to assign schedule to application ID " + appId + ".");
            }

        } catch (SQLException e) {
            request.setAttribute("error", "Database error: " + e.getMessage());
            e.printStackTrace();
        } catch (ClassNotFoundException e) {
            request.setAttribute("error", "Database driver not found: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
        }

        // Redirect based on role
        response.sendRedirect("Trainer".equals(role) ? "trainerDashboard.jsp" : "adminDashboard.jsp");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Redirect GET requests to viewApplications.jsp
        response.sendRedirect("viewApplications.jsp");
    }
}