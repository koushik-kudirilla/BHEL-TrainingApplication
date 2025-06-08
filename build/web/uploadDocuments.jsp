
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="jakarta.servlet.http.*, jakarta.servlet.*, java.util.*" %>
<%@ page import="utils.DBConnection, java.sql.*" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Upload Documents - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <script>
        // Store PDF URLs to revoke them later
        let pdfUrls = [];

        function previewFiles() {
            const previewSection = document.getElementById("previewSection");
            const previewList = document.getElementById("previewList");
            const uploadButton = document.getElementById("uploadButton");
            const confirmButton = document.getElementById("confirmButton");
            const cancelButton = document.getElementById("cancelButton");

            // Clear previous preview and revoke old PDF URLs
            previewList.innerHTML = "";
            pdfUrls.forEach(url => URL.revokeObjectURL(url));
            pdfUrls = [];

            let allValid = true;

            const fields = ["institute_letter", "aadhaar", "photo", "college_id"];
            const labels = {
                "institute_letter": "Institute Letter (Request for Training/NOC)",
                "aadhaar": "Aadhaar Card",
                "photo": "Passport Size Photo",
                "college_id": "College ID"
            };
            const maxSize = 5 * 1024 * 1024; // 5MB in bytes

            fields.forEach(field => {
                const input = document.querySelector('input[name="' + field + '"]');
                const file = input.files[0];
                const li = document.createElement("li");
                const fileInfo = document.createElement("div");
                fileInfo.className = "file-info";
                const filePreview = document.createElement("div");
                filePreview.className = "file-preview";

                if (!file) {
                    fileInfo.textContent = labels[field] + ": No file selected";
                    fileInfo.style.color = "red";
                    allValid = false;
                } else {
                    const extension = file.name.split('.').pop().toLowerCase();
                    const validExtensions = field === "photo" ? ["jpg", "jpeg"] : ["pdf", "jpg", "jpeg"];
                    if (!validExtensions.includes(extension)) {
                        fileInfo.textContent = labels[field] + ": Invalid file format (" + file.name + "). Allowed formats: " + validExtensions.join("/");
                        fileInfo.style.color = "red";
                        allValid = false;
                    } else if (file.size > maxSize) {
                        fileInfo.textContent = labels[field] + ": File too large (" + (file.size / 1024 / 1024).toFixed(2) + "MB). Max size: 5MB";
                        fileInfo.style.color = "red";
                        allValid = false;
                    } else {
                        fileInfo.textContent = labels[field] + ": " + file.name + " (" + (file.size / 1024 / 1024).toFixed(2) + "MB)";
                        fileInfo.style.color = "green";

                        // Handle preview
                        if (extension === "jpg" || extension === "jpeg") {
                            const img = document.createElement("img");
                            const reader = new FileReader();
                            reader.onload = function(e) {
                                img.src = e.target.result;
                            };
                            reader.readAsDataURL(file);
                            filePreview.appendChild(img);
                        } else if (extension === "pdf") {
                            const pdfLink = document.createElement("a");
                            pdfLink.className = "btn view-btn ";
                            pdfLink.textContent = "View PDF";
                            pdfLink.href = URL.createObjectURL(file);
                            pdfLink.target = "_blank";
                            pdfUrls.push(pdfLink.href);
                            filePreview.appendChild(pdfLink);
                        }
                    }
                }

                li.appendChild(filePreview);
                li.appendChild(fileInfo);
                previewList.appendChild(li);
            });

            previewSection.style.display = "block";
            uploadButton.style.display = "none";
            confirmButton.style.display = allValid ? "inline-block" : "none";
            cancelButton.style.display = "inline-block";
        }

        function cancelPreview() {
            const previewSection = document.getElementById("previewSection");
            const uploadButton = document.getElementById("uploadButton");
            const confirmButton = document.getElementById("confirmButton");
            const cancelButton = document.getElementById("cancelButton");
            const fields = ["institute_letter", "aadhaar", "photo", "college_id"];

            // Clear file inputs
            fields.forEach(field => {
                const input = document.querySelector('input[name="' + field + '"]');
                input.value = "";
            });

            // Revoke PDF URLs
            pdfUrls.forEach(url => URL.revokeObjectURL(url));
            pdfUrls = [];

            previewSection.style.display = "none";
            uploadButton.style.display = "inline-block";
            confirmButton.style.display = "none";
            cancelButton.style.display = "none";
        }

        function submitForm() {
            // Revoke PDF URLs before submission to free memory
            pdfUrls.forEach(url => URL.revokeObjectURL(url));
            pdfUrls = [];
            document.getElementById("uploadForm").submit();
        }

        // Add event listeners to file inputs to update preview on change
        window.onload = function() {
            const fields = ["institute_letter", "aadhaar", "photo", "college_id"];
            fields.forEach(field => {
                const input = document.querySelector('input[name="' + field + '"]');
                input.addEventListener('change', () => {
                    if (document.getElementById("previewSection").style.display === "block") {
                        previewFiles();
                    }
                });
            });
        };
    </script>
</head>
<body>
<jsp:include page="navbar.jsp" />
<div class="container">
    <div class="hero">
        <div class="hero-content">
            <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
            <h1>Upload Documents - BHEL HRDC</h1>
            <p>Upload your institute letter, Aadhaar, photo, and college ID for training application.</p>
        </div>
    </div>

    <%
        String message = (String) request.getAttribute("message");
        if (message != null) {
    %>
    <div class="alert <%= message.startsWith("Server error") || message.startsWith("Failed") ? "alert-error" : "alert-success" %>">
        <p><%= message %></p>
    </div>
    <%
        }
        String username = (String) session.getAttribute("username");
        String role = (String) session.getAttribute("role");

        if (username == null || !"Trainee".equals(role)) {
            response.sendRedirect("traineeLogin.jsp");
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        boolean documentsUploaded = false;

        try {
            conn = DBConnection.getConnection();

            // Fetch the latest application for the user
            String sql = "SELECT institute_letter_path, aadhaar_path, photo_path, college_id_path " +
                        "FROM bhel_training_application " +
                        "WHERE user_id = (SELECT id FROM users WHERE username = ?) " +
                        "ORDER BY id DESC LIMIT 1";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();

            if (rs.next()) {
                String instituteLetterPath = rs.getString("institute_letter_path");
                String aadhaarPath = rs.getString("aadhaar_path");
                String photoPath = rs.getString("photo_path");
                String collegeIdPath = rs.getString("college_id_path");

                // Check if any document has been uploaded
                documentsUploaded = (instituteLetterPath != null || aadhaarPath != null || 
                                    photoPath != null || collegeIdPath != null);
            }
        } catch (Exception e) {
            e.printStackTrace();
    %>
    <div class="alert alert-error">
        <p>Error: Unable to check document status. Please try again later.</p>
    </div>
    <%
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
        }

        if (documentsUploaded && message == null) {
    %>
    <div class="alert alert-info">
        <p>Documents have already been uploaded for your latest application.</p>
        <p><a href="traineeDashboard.jsp" class="btn secondary-cta-btn">Back to Dashboard</a></p>
    </div>
    <%
        } else if ( message == null){
    %>
    <div class="content">
        <form id="uploadForm" action="UploadDocumentsServlet" method="post" enctype="multipart/form-data">
            <div class="form-group">
                <label>Institute Letter (Request for Training/NOC) (PDF/JPG/JPEG, max 5MB):</label>
                <input type="file" name="institute_letter" accept=".pdf,.jpg,.jpeg" required aria-required="true">
            </div>
            <div class="form-group">
                <label>Aadhaar Card (PDF/JPG/JPEG, max 5MB):</label>
                <input type="file" name="aadhaar" accept=".pdf,.jpg,.jpeg" required aria-required="true">
            </div>
            <div class="form-group">
                <label>Passport Size Photo (JPG/JPEG, max 5MB):</label>
                <input type="file" name="photo" accept=".jpg,.jpeg" required aria-required="true">
            </div>
            <div class="form-group">
                <label>College ID (PDF/JPG/JPEG, max 5MB):</label>
                <input type="file" name="college_id" accept=".pdf,.jpg,.jpeg" required aria-required="true">
            </div>
            <button type="button" id="uploadButton" class="btn cta-btn" onclick="previewFiles()">Preview Documents</button>
            <div id="previewSection" class="preview-section">
                <h3>Document Preview</h3>
                <ul id="previewList"></ul>
                <div class="btn-container">
                    <button type="button" id="confirmButton" class="btn cta-btn" onclick="submitForm()" style="display: none;">Confirm & Upload</button>
                    <button type="button" id="cancelButton" class="btn secondary-cta-btn" onclick="cancelPreview()" style="display: none;">Cancel</button>
                </div>
            </div>
        </form>
        <p>Files will be securely stored and reviewed by administrators.</p>
        <a href="traineeDashboard.jsp" class="btn secondary-cta-btn">Back to Dashboard</a>
    </div>
    <%
        }
    %>
</div>
<jsp:include page="footer.jsp" />
</body>
</html>