package servlets;

import java.io.*;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.json.*;
import utils.DBConnection;

@WebServlet("/processPaymentServlet")
public class ProcessPaymentServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        JsonObjectBuilder jsonResponseBuilder = Json.createObjectBuilder();

        try {
            String appIdParam = request.getParameter("appId");
            int appId;
            try {
                appId = Integer.parseInt(appIdParam);
            } catch (NumberFormatException e) {
                jsonResponseBuilder.add("success", false)
                                   .add("message", "Invalid application ID");
                out.print(jsonResponseBuilder.build().toString());
                out.flush();
                return;
            }

            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                 conn = DBConnection.getConnection();
                // Check if payment_status column exists
                boolean hasPaymentStatus = false;
                DatabaseMetaData meta = conn.getMetaData();
                ResultSet columns = meta.getColumns(null, null, "bhel_training_application", "payment_status");
                if (columns.next()) {
                    hasPaymentStatus = true;
                }

                // Verify application exists and payment is pending (if column exists)
                String sql = "SELECT training_program" + (hasPaymentStatus ? ", payment_status" : "") +
                            " FROM bhel_training_application WHERE id = ? AND status = 'Approved'";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, appId);
                rs = pstmt.executeQuery();

                if (!rs.next()) {
                    jsonResponseBuilder.add("success", false)
                                       .add("message", "Application not found or not Approved");
                    out.print(jsonResponseBuilder.build().toString());
                    out.flush();
                    return;
                }

                if (hasPaymentStatus && !"Pending".equals(rs.getString("payment_status"))) {
                    jsonResponseBuilder.add("success", false)
                                       .add("message", "Payment not pending");
                    out.print(jsonResponseBuilder.build().toString());
                    out.flush();
                    return;
                }

                // Simulate payment processing
                String transactionId = "TXN" + System.currentTimeMillis();

                // Check if payment_transactions table exists
                boolean hasPaymentTransactions = false;
                ResultSet tables = meta.getTables(null, null, "payment_transactions", null);
                if (tables.next()) {
                    hasPaymentTransactions = true;
                }

                if (hasPaymentTransactions) {
                    // Record payment in payment_transactions
                    sql = "INSERT INTO payment_transactions (application_id, transaction_id, amount, status, payment_date) " +
                          "SELECT id, ?, training_fee, 'Completed', CURDATE() FROM bhel_training_application WHERE id = ?";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, transactionId);
                    pstmt.setInt(2, appId);
                    pstmt.executeUpdate();
                }

                if (hasPaymentStatus) {
                    // Update payment status in bhel_training_application
                    sql = "UPDATE bhel_training_application SET payment_status = 'Paid', payment_date = CURDATE() WHERE id = ?";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setInt(1, appId);
                    pstmt.executeUpdate();
                }

                // Assign a schedule automatically
                sql = "SELECT id FROM training_schedules WHERE training_type = ? AND start_date >= CURDATE() LIMIT 1";
                pstmt = conn.prepareStatement(sql);
                pstmt.setString(1, rs.getString("training_program"));
                rs = pstmt.executeQuery();

                if (rs.next()) {
                    int scheduleId = rs.getInt("id");
                    sql = "INSERT INTO trainee_schedules (application_id, schedule_id, progress) VALUES (?, ?, 'Not Started')";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setInt(1, appId);
                    pstmt.setInt(2, scheduleId);
                    pstmt.executeUpdate();
                } else {
                    System.out.println("No available schedule found for App ID " + appId);
                }

                // Simulate email notification
                System.out.println("Sending email notification for payment confirmation: App ID " + appId);

                jsonResponseBuilder.add("success", true)
                                   .add("message", "Payment processed successfully");
            } catch (Exception e) {
                System.out.println("Error processing payment: " + e.getMessage());
                jsonResponseBuilder.add("success", false)
                                   .add("message", "Error processing payment: " + e.getMessage());
            } finally {
                if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
                if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
            }
        } catch (Exception e) {
            jsonResponseBuilder.add("success", false)
                               .add("message", "Server error: " + e.getMessage());
        }

        out.print(jsonResponseBuilder.build().toString());
        out.flush();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setStatus(HttpServletResponse.SC_METHOD_NOT_ALLOWED); // 405
        PrintWriter out = response.getWriter();
        JsonObjectBuilder jsonResponseBuilder = Json.createObjectBuilder();
        jsonResponseBuilder.add("success", false)
                           .add("message", "HTTP method GET is not supported by this URL. Use POST instead.");
        out.print(jsonResponseBuilder.build().toString());
        out.flush();
    }
}