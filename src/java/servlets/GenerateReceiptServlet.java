package servlets;

import java.io.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.WebServlet;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.element.Paragraph;
import com.itextpdf.layout.element.Table;
import com.itextpdf.layout.element.Cell;
import com.itextpdf.layout.properties.UnitValue;
import com.itextpdf.layout.properties.TextAlignment;
import com.itextpdf.layout.borders.SolidBorder;
import com.itextpdf.kernel.geom.PageSize;
import com.itextpdf.kernel.colors.ColorConstants;
import com.itextpdf.layout.element.LineSeparator;
import com.itextpdf.kernel.pdf.canvas.draw.SolidLine;
import java.sql.*;
import java.text.NumberFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.function.BiConsumer;
import utils.DBConnection;

@WebServlet("/generateReceipt")
public class GenerateReceiptServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Get session attributes
        HttpSession session = request.getSession(false);
        String username = (session != null) ? (String) session.getAttribute("username") : null;
        String role = (session != null) ? (String) session.getAttribute("role") : null;

        // Validate session
        if (username == null || role == null || !"Trainee".equals(role)) {
            System.out.println("Unauthorized access attempt to generate receipt at " + 
                new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
            response.sendRedirect("login.jsp");
            return;
        }

        // Get appId parameter
        String appIdParam = request.getParameter("appId");
        int appId;
        try {
            appId = Integer.parseInt(appIdParam);
            if (appId <= 0) {
                System.out.println("Invalid application ID: " + appIdParam);
                response.sendRedirect("traineeDashboard.jsp?error=Invalid+application+ID");
                return;
            }
        } catch (NumberFormatException e) {
            System.out.println("Invalid application ID format: " + appIdParam);
            response.sendRedirect("traineeDashboard.jsp?error=Invalid+application+ID+format");
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        PdfWriter writer = null;
        PdfDocument pdf = null;
        Document document = null;

        try {
            // Database connection
             conn = DBConnection.getConnection();
            // Check if payment_status, payment_date, and discount columns exist
            boolean hasPaymentStatus = false;
            boolean hasPaymentDate = false;
            boolean hasDiscount = false;
            DatabaseMetaData meta = conn.getMetaData();
            ResultSet columns = meta.getColumns(null, null, "bhel_training_application", "payment_status");
            if (columns.next()) {
                hasPaymentStatus = true;
            }
            columns = meta.getColumns(null, null, "bhel_training_application", "payment_date");
            if (columns.next()) {
                hasPaymentDate = true;
            }
            columns = meta.getColumns(null, null, "bhel_training_application", "discount");
            if (columns.next()) {
                hasDiscount = true;
            }

            // Fetch application details
            String sql = "SELECT training_program, training_period, training_fee" +
                        (hasPaymentStatus ? ", payment_status" : "") +
                        (hasPaymentDate ? ", payment_date" : "") +
                        (hasDiscount ? ", discount" : "") +
                        " FROM bhel_training_application " +
                        "WHERE id = ? AND user_id = (SELECT id FROM users WHERE username = ?) AND status = 'Approved'";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, appId);
            pstmt.setString(2, username);
            rs = pstmt.executeQuery();

            if (!rs.next()) {
                System.out.println("Application not found or not Approved: App ID " + appId);
                response.sendRedirect("traineeDashboard.jsp?error=Application+not+found+or+not+Approved");
                return;
            }

            String trainingProgram = rs.getString("training_program");
            String trainingPeriod = rs.getString("training_period");
            double totalFee = rs.getDouble("training_fee");
            String paymentStatus = hasPaymentStatus ? rs.getString("payment_status") : "N/A";
            Date paymentDate = hasPaymentDate ? rs.getDate("payment_date") : null;
            double discount = hasDiscount ? rs.getDouble("discount") : 0.0;

            // Validate payment status if column exists
            if (hasPaymentStatus && !"Paid".equals(paymentStatus)) {
                System.out.println("Cannot generate receipt for unpaid application: App ID " + appId);
                response.sendRedirect("feeDetail.jsp?appId=" + appId + "&error=Payment+not+completed");
                return;
            }

            // Map training program to fee table
            String feeTableName;
            switch (trainingProgram) {
                case "Diploma (6 Months)":
                    feeTableName = "Diploma6Months";
                    break;
                case "Graduate (3 Years)":
                    feeTableName = "Graduate3Years";
                    break;
                case "Graduate (4 Years)":
                    feeTableName = "Graduate4Years";
                    break;
                case "Postgraduate":
                    feeTableName = "PostGraduate";
                    break;
                default:
                    System.out.println("Invalid training program: " + trainingProgram);
                    response.sendRedirect("traineeDashboard.jsp?error=Invalid+training+program");
                    return;
            }

            // Fetch fee breakdown
            double serviceCharges = 0.0, cgst = 0.0, sgst = 0.0;
            sql = "SELECT ServiceCharges, CGST, SGST FROM " + feeTableName + " WHERE Duration = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, trainingPeriod);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                serviceCharges = rs.getDouble("ServiceCharges");
                cgst = rs.getDouble("CGST");
                sgst = rs.getDouble("SGST");
            } else {
                System.out.println("Fee details not found for program: " + trainingProgram + ", period: " + trainingPeriod);
                response.sendRedirect("traineeDashboard.jsp?error=Fee+details+not+found+for+selected+program+and+period");
                return;
            }

            // Apply discount to total fee
            double discountedFee = totalFee - discount;

            // Calculate base fee
            double baseFee = totalFee - (serviceCharges + cgst + sgst);

            // Format currency in INR
            NumberFormat currencyFormat = NumberFormat.getCurrencyInstance(new Locale("en", "IN"));

            // Set response headers for PDF download
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=receipt_appId_" + appId + ".pdf");
            response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
            response.setHeader("Pragma", "no-cache");
            response.setHeader("Expires", "0");

            // Initialize PDF generation
            OutputStream outputStream = response.getOutputStream();
            writer = new PdfWriter(outputStream);
            pdf = new PdfDocument(writer);
            document = new Document(pdf, PageSize.A4);
            document.setMargins(36, 36, 36, 36); // 1-inch margins

            // Add header
            Paragraph header = new Paragraph("BHEL HRDC - Payment Receipt")
                .setBold()
                .setFontSize(18)
                .setTextAlignment(TextAlignment.CENTER)
                .setMarginBottom(5);
            document.add(header);

            Paragraph orgName = new Paragraph("Bharat Heavy Electricals Limited")
                .setFontSize(14)
                .setTextAlignment(TextAlignment.CENTER)
                .setMarginBottom(5);
            document.add(orgName);

            Paragraph address = new Paragraph("HPVP Vizag, Andhra Pradesh, India")
                .setFontSize(10)
                .setTextAlignment(TextAlignment.CENTER)
                .setMarginBottom(10);
            document.add(address);

            // Add receipt number
            String receiptNumber = "BHEL-HRDC-" + appId + "-" + System.currentTimeMillis();
            Paragraph receiptNo = new Paragraph("Receipt No: " + receiptNumber)
                .setFontSize(10)
                .setTextAlignment(TextAlignment.RIGHT)
                .setMarginBottom(10);
            document.add(receiptNo);

            // Add horizontal line
            document.add(new LineSeparator(new SolidLine(1f)).setMarginBottom(10));

            // Add application details
            float[] detailWidths = {1, 2};
            Table detailTable = new Table(UnitValue.createPercentArray(detailWidths))
                .setWidth(UnitValue.createPercentValue(80))
                .setMarginLeft(36);
            BiConsumer<String, String> addDetail = (label, value) -> {
                detailTable.addCell(new Cell()
                    .add(new Paragraph(label).setFontSize(11))
                    .setBorder(SolidBorder.NO_BORDER)
                    .setPadding(3));
                detailTable.addCell(new Cell()
                    .add(new Paragraph(value != null ? value : "N/A").setFontSize(11))
                    .setBorder(SolidBorder.NO_BORDER)
                    .setPadding(3));
            };

            addDetail.accept("Application ID:", String.valueOf(appId));
            addDetail.accept("Trainee:", username);
            addDetail.accept("Training Program:", trainingProgram);
            addDetail.accept("Duration:", trainingPeriod);
            if (hasPaymentDate && paymentDate != null) {
                addDetail.accept("Payment Date:", new SimpleDateFormat("dd-MM-yyyy").format(paymentDate));
            }
            document.add(detailTable);

            // Add spacing
            document.add(new Paragraph("\n"));

            // Add fee breakdown table (single declaration)
            float[] columnWidths = {3, 2};
            Table feeTable = new Table(UnitValue.createPercentArray(columnWidths))
                .setWidth(UnitValue.createPercentValue(80))
                .setMarginLeft(36)
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f));

            // Table headers
            feeTable.addCell(new Cell()
                .add(new Paragraph("Description").setBold().setFontSize(11))
                .setBackgroundColor(ColorConstants.LIGHT_GRAY)
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            feeTable.addCell(new Cell()
                .add(new Paragraph("Amount (INR)").setBold().setFontSize(11))
                .setBackgroundColor(ColorConstants.LIGHT_GRAY)
                .setTextAlignment(TextAlignment.RIGHT)
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));

            // Table rows
            feeTable.addCell(new Cell()
                .add(new Paragraph("Base Fee").setFontSize(10))
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            feeTable.addCell(new Cell()
                .add(new Paragraph(currencyFormat.format(baseFee)).setFontSize(10))
                .setTextAlignment(TextAlignment.RIGHT)
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));

            feeTable.addCell(new Cell()
                .add(new Paragraph("Service Charges").setFontSize(10))
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            feeTable.addCell(new Cell()
                .add(new Paragraph(currencyFormat.format(serviceCharges)).setFontSize(10))
                .setTextAlignment(TextAlignment.RIGHT)
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));

            feeTable.addCell(new Cell()
                .add(new Paragraph("CGST (9%)").setFontSize(10))
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            feeTable.addCell(new Cell()
                .add(new Paragraph(currencyFormat.format(cgst)).setFontSize(10))
                .setTextAlignment(TextAlignment.RIGHT)
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));

            feeTable.addCell(new Cell()
                .add(new Paragraph("SGST (9%)").setFontSize(10))
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            feeTable.addCell(new Cell()
                .add(new Paragraph(currencyFormat.format(sgst)).setFontSize(10))
                .setTextAlignment(TextAlignment.RIGHT)
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));

            if (hasDiscount && discount > 0) {
                feeTable.addCell(new Cell()
                    .add(new Paragraph("Discount").setFontSize(10))
                    .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                    .setPadding(5));
                feeTable.addCell(new Cell()
                    .add(new Paragraph("-" + currencyFormat.format(discount)).setFontSize(10))
                    .setTextAlignment(TextAlignment.RIGHT)
                    .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                    .setPadding(5));
            }

            feeTable.addCell(new Cell()
                .add(new Paragraph("Total Fee").setBold().setFontSize(11))
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            feeTable.addCell(new Cell()
                .add(new Paragraph(currencyFormat.format(discountedFee)).setBold().setFontSize(11))
                .setTextAlignment(TextAlignment.RIGHT)
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));

            document.add(feeTable);

            // Add footer
            document.add(new LineSeparator(new SolidLine(1f)).setMarginTop(20));
            document.add(new Paragraph("Thank You for Your Payment!")
                .setFontSize(12)
                .setTextAlignment(TextAlignment.CENTER)
                .setMarginTop(10));
            document.add(new Paragraph("BHEL HRDC | Contact: hrdc@bhel.com | +91-40-28581111")
                .setFontSize(10)
                .setTextAlignment(TextAlignment.CENTER)
                .setMarginTop(5));
            document.add(new Paragraph("© 2025 BHEL. All rights reserved.")
                .setFontSize(10)
                .setTextAlignment(TextAlignment.CENTER));

            // Close the document
            document.close();
            pdf.close();
            writer.close();
            outputStream.flush();

            System.out.println("Receipt generated successfully for App ID " + appId);

        } catch (SQLException e) {
            System.out.println("Database error while generating receipt: " + e.getMessage());
            if (writer == null) {
                response.sendRedirect("feeDetail.jsp?appId=" + appId + "&error=Database+error:+" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
            } else {
                System.out.println("Error after starting PDF generation, cannot redirect: " + e.getMessage());
            }
        } catch (Exception e) {
            System.out.println("Error generating receipt: " + e.getMessage());
            if (writer == null) {
                response.sendRedirect("feeDetail.jsp?appId=" + appId + "&error=Server+error:+" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
            } else {
                System.out.println("Error after starting PDF generation, cannot redirect: " + e.getMessage());
            }
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "HTTP method POST is not supported by this URL. Use GET instead.");
    }
}