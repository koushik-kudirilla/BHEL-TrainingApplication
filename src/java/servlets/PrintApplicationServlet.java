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
import com.itextpdf.layout.borders.Border;
import com.itextpdf.layout.borders.SolidBorder;
import com.itextpdf.kernel.geom.PageSize;
import com.itextpdf.kernel.colors.ColorConstants;
import com.itextpdf.layout.element.LineSeparator;
import com.itextpdf.kernel.pdf.canvas.draw.SolidLine;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.function.BiConsumer;
import utils.DBConnection;

@WebServlet("/printApplication")
public class PrintApplicationServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Get session attributes
        HttpSession session = request.getSession(false);
        String username = (session != null) ? (String) session.getAttribute("username") : null;
        String role = (session != null) ? (String) session.getAttribute("role") : null;

        // Validate session
        if (username == null || role == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        // Get appId parameter
        String appIdParam = request.getParameter("appId");
        int appId;
        try {
            appId = Integer.parseInt(appIdParam);
            if (appId <= 0) {
                response.sendRedirect("viewApplications.jsp?error=Invalid+application+ID");
                return;
            }
        } catch (NumberFormatException e) {
            response.sendRedirect("viewApplications.jsp?error=Invalid+application+ID+format");
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
            // Fetch application details
            String sql;
            if ("Trainee".equals(role)) {
                sql = "SELECT a.id, a.applicant_name, a.institute_name, a.trade, a.roll_no, a.batch, a.year_of_study, " +
                      "a.dob, a.guardian_name, a.so_do, a.address, a.contact_number, a.aadhaar_number, " +
                      "a.training_required, a.training_program, a.training_period, a.sub_caste, a.email, a.gender, " +
                      "ts.schedule_id, ts.progress, s.start_date, s.end_date " +
                      "FROM bhel_training_application a " +
                      "LEFT JOIN trainee_schedules ts ON a.id = ts.application_id " +
                      "LEFT JOIN training_schedules s ON ts.schedule_id = s.id " +
                      "WHERE a.id = ? AND a.user_id = (SELECT id FROM users WHERE username = ?)";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, appId);
                pstmt.setString(2, username);
            } else if ("Admin".equals(role) || "Trainer".equals(role)) {
                sql = "SELECT a.id, a.applicant_name, a.institute_name, a.trade, a.roll_no, a.batch, a.year_of_study, " +
                      "a.dob, a.guardian_name, a.so_do, a.address, a.contact_number, a.aadhaar_number, " +
                      "a.training_required, a.training_program, a.training_period, a.sub_caste, a.email, a.gender, " +
                      "ts.schedule_id, ts.progress, s.start_date, s.end_date " +
                      "FROM bhel_training_application a " +
                      "LEFT JOIN trainee_schedules ts ON a.id = ts.application_id " +
                      "LEFT JOIN training_schedules s ON ts.schedule_id = s.id " +
                      "WHERE a.id = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, appId);
            } else {
                response.sendRedirect("viewApplications.jsp?error=Unauthorized+role");
                return;
            }

            rs = pstmt.executeQuery();

            if (!rs.next()) {
                response.sendRedirect("viewApplications.jsp?error=Application+not+found+or+unauthorized");
                return;
            }

            // Extract application details
            int applicationId = rs.getInt("id");
            String applicantName = rs.getString("applicant_name");
            String instituteName = rs.getString("institute_name");
            String trade = rs.getString("trade");
            String rollNo = rs.getString("roll_no");
            String batch = rs.getString("batch");
            String yearOfStudy = rs.getString("year_of_study");
            Date dob = rs.getDate("dob");
            String guardianName = rs.getString("guardian_name");
            String soDo = rs.getString("so_do");
            String address = rs.getString("address");
            String contactNumber = rs.getString("contact_number");
            String aadhaarNumber = rs.getString("aadhaar_number");
            String trainingRequired = rs.getString("training_required");
            String trainingProgram = rs.getString("training_program");
            String trainingPeriod = rs.getString("training_period");
            String subCaste = rs.getString("sub_caste");
            String email = rs.getString("email");
            String gender = rs.getString("gender");
            String scheduleId = rs.getString("schedule_id");
            String progress = rs.getString("progress");
            String scheduleDetails = scheduleId != null ? 
                "From " + rs.getDate("start_date") + " to " + rs.getDate("end_date") : 
                "Not Assigned";

            // Set response headers for PDF download
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=application_form_" + appId + ".pdf");
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
            Paragraph header = new Paragraph("APPLICATION FORM FOR TRAINING AT BHEL HPVP VIZAG")
                .setBold()
                .setFontSize(16)
                .setTextAlignment(TextAlignment.CENTER)
                .setMarginBottom(5);
            document.add(header);

            Paragraph subHeader = new Paragraph("[ITI / VOCATIONAL / DCCP / DIPLOMA 6 MONTHS / INTERNSHIP / DIPLOMA / DEGREE / PG]")
                .setFontSize(10)
                .setTextAlignment(TextAlignment.CENTER)
                .setMarginBottom(5);
            document.add(subHeader);

            Paragraph orgName = new Paragraph("Bharat Heavy Electricals Limited")
                .setFontSize(12)
                .setTextAlignment(TextAlignment.CENTER)
                .setMarginBottom(5);
            document.add(orgName);

            // Add a horizontal line to separate header
            LineSeparator separator = new LineSeparator(new SolidLine(1f));
            separator.setMarginBottom(10);
            document.add(separator);

            // Create a table for form fields (2 columns: Label and Value)
            float[] columnWidths = {2, 4};
            Table formTable = new Table(UnitValue.createPercentArray(columnWidths));
            formTable.setWidth(UnitValue.createPercentValue(100));
            formTable.setBorder(Border.NO_BORDER);

            // Helper method to add a form field row
            BiConsumer<String, String> addFormField = (label, value) -> {
                Cell labelCell = new Cell()
                    .add(new Paragraph(label).setFontSize(12))
                    .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                    .setPadding(5);
                Cell valueCell = new Cell()
                    .add(new Paragraph(value != null ? value : "N/A").setFontSize(12))
                    .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                    .setPadding(5);
                formTable.addCell(labelCell);
                formTable.addCell(valueCell);
            };

            // 1. Applicant Name
            addFormField.accept("1. Applicant Name:", applicantName);

            // 2. Institute Name
            addFormField.accept("2. Institute Name:", instituteName);

            // 3. Trade / Diploma / Degree / PG
            addFormField.accept("3. Trade / Diploma / Degree / PG:", trade);

            // 4. Roll No, Batch, Year of Study (inline fields)
            float[] inlineWidths = {1, 1, 1};
            Table inlineTable1 = new Table(UnitValue.createPercentArray(inlineWidths));
            inlineTable1.setWidth(UnitValue.createPercentValue(100));
            inlineTable1.addCell(new Cell()
                .add(new Paragraph("Roll No: " + (rollNo != null ? rollNo : "N/A")).setFontSize(12))
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            inlineTable1.addCell(new Cell()
                .add(new Paragraph("Batch: " + (batch != null ? batch : "N/A")).setFontSize(12))
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            inlineTable1.addCell(new Cell()
                .add(new Paragraph("Year of Study: " + (yearOfStudy != null ? yearOfStudy : "N/A")).setFontSize(12))
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            formTable.addCell(new Cell()
                .add(new Paragraph("4.").setFontSize(12))
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            formTable.addCell(new Cell()
                .add(inlineTable1)
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(0));

            // 5. Date of Birth
            addFormField.accept("5. Date of Birth as per SSC certificate:", dob != null ? new SimpleDateFormat("yyyy-MM-dd").format(dob) : "N/A");

            // 6. Father's / Guardian's Name
            addFormField.accept("6. Father's / Guardian's Name:", guardianName);

            // 7. S/o, D/o, W/o
            addFormField.accept("7. S/o, D/o, W/o:", soDo);

            // 8. Address for Communication (multi-line field)
            addFormField.accept("8. Address for Communication:", address != null ? address : "N/A");
            formTable.getCell(formTable.getNumberOfRows() - 1, 1).setMinHeight(50); // Adjust height for address field

            // 9. Contact Number and Aadhaar Number (inline fields)
            float[] inlineWidths2 = {1, 1};
            Table inlineTable2 = new Table(UnitValue.createPercentArray(inlineWidths2));
            inlineTable2.setWidth(UnitValue.createPercentValue(100));
            inlineTable2.addCell(new Cell()
                .add(new Paragraph("Contact Mobile No: " + (contactNumber != null ? contactNumber : "N/A")).setFontSize(12))
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            inlineTable2.addCell(new Cell()
                .add(new Paragraph("Aadhaar No: " + (aadhaarNumber != null ? aadhaarNumber : "N/A")).setFontSize(12))
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            formTable.addCell(new Cell()
                .add(new Paragraph("9.").setFontSize(12))
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(5));
            formTable.addCell(new Cell()
                .add(inlineTable2)
                .setBorder(new SolidBorder(ColorConstants.BLACK, 0.5f))
                .setPadding(0));

            // 10. Training Required
            addFormField.accept("10. Training Required:", trainingRequired);

            // 11. Training Program
            addFormField.accept("11. Training Program:", trainingProgram);

            // 12. Training Period
            addFormField.accept("12. Training Period:", trainingPeriod);

            // 13. Sub Caste
            addFormField.accept("13. Sub Caste:", subCaste);

            // 14. Mail ID
            addFormField.accept("14. Mail ID:", email);

            // 15. Gender
            addFormField.accept("15. Gender:", gender);

            // 16. Schedule
            addFormField.accept("16. Schedule:", scheduleDetails);

            // 17. Progress
            addFormField.accept("17. Progress:", progress != null ? progress : "N/A");

            // Add the form table to the document
            document.add(formTable);

            // Add a horizontal line to separate form from footer
            document.add(new LineSeparator(new SolidLine(1f)).setMarginTop(10));

            // Add footer
            Paragraph footer = new Paragraph("BHEL HRDC | Contact: hrdc@bhel.com | +91-40-28581111")
                .setFontSize(10)
                .setTextAlignment(TextAlignment.CENTER)
                .setMarginTop(5);
            document.add(footer);

            Paragraph copyright = new Paragraph("© 2025 BHEL. All rights reserved.")
                .setFontSize(10)
                .setTextAlignment(TextAlignment.CENTER);
            document.add(copyright);

            // Close the document
            document.close();
            pdf.close();
            writer.close();
            outputStream.flush();

            System.out.println("PDF generated successfully for Application ID: " + appId);

        } catch (SQLException e) {
            System.out.println("Database error while generating PDF: " + e.getMessage());
            response.sendRedirect("viewApplications.jsp?error=Database+error:+" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        } catch (Exception e) {
            System.out.println("Error generating PDF: " + e.getMessage());
            response.sendRedirect("viewApplications.jsp?error=Server+error:+" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
            if (document != null) document.close();
            if (pdf != null) pdf.close();
            if (writer != null) writer.close();
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "HTTP method POST is not supported by this URL. Use GET instead.");
    }
}