<%@ page language="java" contentType="application/pdf; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.text.NumberFormat, java.util.Locale, java.text.SimpleDateFormat, java.util.Date"%>
<%@ page import="com.itextpdf.kernel.pdf.PdfDocument, com.itextpdf.kernel.pdf.PdfWriter"%>
<%@ page import="com.itextpdf.layout.Document, com.itextpdf.layout.element.Paragraph, com.itextpdf.layout.element.Table, com.itextpdf.layout.property.TextAlignment"%>
<%@ page import="com.itextpdf.layout.element.Cell, com.itextpdf.kernel.colors.ColorConstants, com.itextpdf.layout.property.UnitValue"%>
<%@ page import="com.itextpdf.kernel.font.PdfFontFactory, com.itextpdf.io.font.constants.StandardFonts"%>
<%@ page import="utils.DBConnection" %>
<%!
    private String formatCurrency(double amount) {
        NumberFormat currencyFormat = NumberFormat.getCurrencyInstance(new Locale("en", "IN"));
        return currencyFormat.format(amount);
    }

    private String getFeeTableName(String trainingProgram) {
        switch (trainingProgram) {
            case "Diploma (6 Months)":
                return "Diploma6Months";
            case "Graduate (3 Years)":
                return "Graduate3Years";
            case "Graduate (4 Years)":
                return "Graduate4Years";
            case "Postgraduate":
                return "PostGraduate";
            default:
                return null;
        }
    }
%>
<%
    // Set response headers for PDF download
    response.setContentType("application/pdf");
    response.setHeader("Content-Disposition", "attachment; filename=receipt_" + request.getParameter("appId") + ".pdf");

    // Session validation
    String username = (String) session.getAttribute("username");
    String role = (String) session.getAttribute("role");
    if (username == null || role == null || !"Trainee".equals(role)) {
        System.out.println("Unauthorized access attempt at " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
        response.sendRedirect("traineeLogin.jsp");
        return;
    }

    // Input validation
    String appIdParam = request.getParameter("appId");
    if (appIdParam == null || appIdParam.trim().isEmpty()) {
        System.out.println("Missing application ID at " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
        response.sendRedirect("traineeDashboard.jsp?error=Missing+application+ID");
        return;
    }

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
    try {
        // Database connection
         conn = DBConnection.getConnection();

        // Check for optional columns
        boolean hasPaymentStatus = false;
        boolean hasDiscount = false;
        boolean hasPaymentDate = false;
        DatabaseMetaData meta = conn.getMetaData();
        ResultSet columns = meta.getColumns(null, null, "bhel_training_application", "payment_status");
        if (columns.next()) {
            hasPaymentStatus = true;
        }
        columns = meta.getColumns(null, null, "bhel_training_application", "discount");
        if (columns.next()) {
            hasDiscount = true;
        }
        columns = meta.getColumns(null, null, "bhel_training_application", "payment_date");
        if (columns.next()) {
            hasPaymentDate = true;
        }

        // Fetch application details
        String sql = "SELECT training_program, training_period, training_fee" +
                     (hasPaymentStatus ? ", payment_status" : "") +
                     (hasDiscount ? ", discount" : "") +
                     (hasPaymentDate ? ", payment_date" : "") +
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
        double discount = hasDiscount ? rs.getDouble("discount") : 0.0;
        Date paymentDate = hasPaymentDate ? rs.getDate("payment_date") : null;

        // Validate payment status
        if (hasPaymentStatus && !"Paid".equals(paymentStatus)) {
            System.out.println("Cannot generate receipt for unpaid application: App ID " + appId);
            response.sendRedirect("feeDetail.jsp?appId=" + appId + "&error=Receipt+can+only+be+generated+for+paid+applications");
            return;
        }

        // Fetch fee details
        String feeTable = getFeeTableName(trainingProgram);
        if (feeTable == null) {
            System.out.println("Invalid training program: " + trainingProgram);
            response.sendRedirect("traineeDashboard.jsp?error=Invalid+training+program");
            return;
        }

        double serviceCharges = 0.0, cgst = 0.0, sgst = 0.0;
        sql = "SELECT ServiceCharges, CGST, SGST FROM " + feeTable + " WHERE Duration = ?";
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

        // Calculate base fee and discounted fee
        double baseFee = totalFee - (serviceCharges + cgst + sgst);
        double discountedFee = totalFee - discount;

        // Initialize PDF document
        PdfWriter writer = new PdfWriter(response.getOutputStream());
        PdfDocument pdf = new PdfDocument(writer);
        Document document = new Document(pdf);

        // Set font
        PdfFontFactory.registerSystemDirectories();
        com.itextpdf.kernel.font.PdfFont font = PdfFontFactory.createFont(StandardFonts.HELVETICA);
        com.itextpdf.kernel.font.PdfFont boldFont = PdfFontFactory.createFont(StandardFonts.HELVETICA_BOLD);

        // Header
        Paragraph header = new Paragraph("BHEL HRDC - Fee Receipt")
            .setFont(boldFont)
            .setFontSize(16)
            .setTextAlignment(TextAlignment.CENTER)
            .setMarginBottom(10);
        document.add(header);

        Paragraph subHeader = new Paragraph("Bharat Heavy Electricals Limited")
            .setFont(font)
            .setFontSize(12)
            .setTextAlignment(TextAlignment.CENTER)
            .setMarginBottom(20);
        document.add(subHeader);

        // Receipt details
        Paragraph receiptDetails = new Paragraph("Receipt for Application ID: " + appId)
            .setFont(font)
            .setFontSize(12)
            .setTextAlignment(TextAlignment.LEFT)
            .setMarginBottom(10);
        document.add(receiptDetails);

        Paragraph issueDate = new Paragraph("Issue Date: May 28, 2025, 03:39 PM IST")
            .setFont(font)
            .setFontSize(10)
            .setTextAlignment(TextAlignment.LEFT)
            .setMarginBottom(20);
        document.add(issueDate);

        // Fee details table
        float[] columnWidths = {2, 3};
        Table table = new Table(UnitValue.createPercentArray(columnWidths)).useAllAvailableWidth();

        // Table headers
        table.addHeaderCell(new Cell().add(new Paragraph("Description").setFont(boldFont)).setBackgroundColor(ColorConstants.LIGHT_GRAY));
        table.addHeaderCell(new Cell().add(new Paragraph("Amount").setFont(boldFont)).setBackgroundColor(ColorConstants.LIGHT_GRAY));

        // Table rows
        table.addCell(new Cell().add(new Paragraph("Training Program").setFont(font)));
        table.addCell(new Cell().add(new Paragraph(trainingProgram).setFont(font)));

        table.addCell(new Cell().add(new Paragraph("Duration").setFont(font)));
        table.addCell(new Cell().add(new Paragraph(trainingPeriod).setFont(font)));

        table.addCell(new Cell().add(new Paragraph("Base Fee").setFont(font)));
        table.addCell(new Cell().add(new Paragraph(formatCurrency(baseFee)).setFont(font)));

        table.addCell(new Cell().add(new Paragraph("Service Charges").setFont(font)));
        table.addCell(new Cell().add(new Paragraph(formatCurrency(serviceCharges)).setFont(font)));

        table.addCell(new Cell().add(new Paragraph("CGST (9%)").setFont(font)));
        table.addCell(new Cell().add(new Paragraph(formatCurrency(cgst)).setFont(font)));

        table.addCell(new Cell().add(new Paragraph("SGST (9%)").setFont(font)));
        table.addCell(new Cell().add(new Paragraph(formatCurrency(sgst)).setFont(font)));

        table.addCell(new Cell().add(new Paragraph("Discount").setFont(font)));
        table.addCell(new Cell().add(new Paragraph(formatCurrency(discount)).setFont(font)));

        table.addCell(new Cell().add(new Paragraph("Total Fee").setFont(boldFont)));
        table.addCell(new Cell().add(new Paragraph(formatCurrency(discountedFee)).setFont(boldFont)));

        if (hasPaymentStatus) {
            table.addCell(new Cell().add(new Paragraph("Payment Status").setFont(font)));
            table.addCell(new Cell().add(new Paragraph(paymentStatus).setFont(font)));
        }

        if (hasPaymentDate && paymentDate != null) {
            table.addCell(new Cell().add(new Paragraph("Payment Date").setFont(font)));
            table.addCell(new Cell().add(new Paragraph(new SimpleDateFormat("dd-MM-yyyy").format(paymentDate)).setFont(font)));
        }

        document.add(table);

        // Footer
        Paragraph footer = new Paragraph("\nThank you for your payment!\nBHEL HRDC | Contact: hrdc@bhel.com | +91-40-28581111")
            .setFont(font)
            .setFontSize(10)
            .setTextAlignment(TextAlignment.CENTER)
            .setMarginTop(20);
        document.add(footer);

        document.close();

    } catch (SQLException e) {
        System.out.println("Database error at " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()) + ": " + e.getMessage());
        response.sendRedirect("feeDetail.jsp?appId=" + appId + "&error=Database+error:+" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
    } catch (Exception e) {
        System.out.println("Server error at " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()) + ": " + e.getMessage());
        response.sendRedirect("feeDetail.jsp?appId=" + appId + "&error=Server+error:+" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
        if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
    }
%>