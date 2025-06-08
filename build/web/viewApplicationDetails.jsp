<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="utils.DBConnection, java.sql.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>View Application Details - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
            padding-bottom: 10px;
            border-bottom: 3px solid #4fd1c5;
            width: 100%;
        }
        .section-header h2 {
            margin: 0;
            font-size: 1.9em;
            font-weight: 500;
        }
        .content h2 {
            border-bottom: none !important;
        }
        .details-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            margin-bottom: 40px;
        }
        .details-card {
            background: #edf2f7;
            padding: 25px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }
        .details-card:hover {
            transform: translateY(-5px);
        }
        .details-card .category {
            margin-bottom: 20px;
            padding-bottom: 15px;
        }
        .details-card .category h3 {
            color: #2c7a7b;
            font-size: 1.2em;
            margin: 0 0 10px;
            font-weight: 500;
            border-bottom: 2px solid #4fd1c5;
            padding-bottom: 5px;
        }
        .details-card .detail-item {
            display: flex;
            align-items: center;
            margin: 12px 0;
            font-size: 1em;
            color: #2d3748;
        }
        .details-card .detail-item i {
            color: #d69e2e;
            margin-right: 12px;
            width: 20px;
            text-align: center;
        }
        .details-card .detail-item strong {
            color: #2c7a7b;
            font-weight: 500;
            width: 150px;
            flex-shrink: 0;
        }
        .documents-card {
            background: #fff;
            padding: 25px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            margin-bottom: 40px;
        }
        .card-list .card {
            margin-bottom: 20px;
            padding: 20px;
        }
        .card-list .card p {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        .action-card {
            background: #fff;
            padding: 25px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            margin-bottom: 40px;
        }
        .action-grid {
            display: flex;
            justify-content: center;
            gap: 20px;
        }
        .card a.view-doc-btn {
            background: linear-gradient(135deg, #2c7a7b, #4fd1c5);
            color: #fff !important;
            padding: 8px 12px;
            border-radius: 5px;
            margin-bottom: 10px;
            text-decoration: none;
            font-size: 0.9em;
            line-height: 1.2;
            box-shadow: 0 2px 8px rgba(0,0,0,0.15);
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .card a.view-doc-btn:hover {
            color: #fff !important;
            text-decoration: none !important;
            transform: scale(1.05);
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }
        @media (max-width: 768px) {
            .details-grid {
                grid-template-columns: 1fr;
            }
            .details-card .detail-item {
                flex-direction: column;
                align-items: flex-start;
            }
            .details-card .detail-item strong {
                width: auto;
                margin-bottom: 5px;
            }
            .action-grid {
                flex-direction: column;
            }
            .card-list .card p {
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }
        }
    </style>
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="container">
        <div class="hero">
            <div class="hero-content">
                <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
                <h1>Application Details</h1>
                <p>Review and manage training application details</p>
            </div>
        </div>
        <%
            String username = (String) session.getAttribute("username");
            String role = (String) session.getAttribute("role");

             if (username == null || role == null || 
                !("Trainee".equals(role) || "Trainer".equals(role) || "Admin".equals(role))) {
                response.sendRedirect("traineeLogin.jsp");
                return;
            }

            String appIdParam = request.getParameter("appId");
            if (appIdParam == null) {
                response.sendRedirect("viewApplications.jsp?error=Invalid+application+ID");
                return;
            }

            int appId;
            try {
                appId = Integer.parseInt(appIdParam);
            } catch (NumberFormatException e) {
                response.sendRedirect("viewApplications.jsp?error=Invalid+application+ID+format");
                return;
            }

            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            String successMessage = null;
            String errorMessage = null;

            try {
                conn = DBConnection.getConnection();

                // Handle Approve/Reject actions (only for Admin)
                if ("POST".equalsIgnoreCase(request.getMethod()) && "Admin".equals(role)) {
                    String action = request.getParameter("action");
                    if (action != null && ("Approve".equals(action) || "Reject".equals(action))) {
                        try {
                            String sql = "UPDATE bhel_training_application SET status = ? WHERE id = ?";
                            pstmt = conn.prepareStatement(sql);
                            pstmt.setString(1, "Approve".equals(action) ? "Approved" : "Rejected");
                            pstmt.setInt(2, appId);
                            int rowsUpdated = pstmt.executeUpdate();

                            if (rowsUpdated > 0) {
                                successMessage = "Application " + ("Approve".equals(action) ? "Approved" : "Rejected") + " successfully!";
                            } else {
                                errorMessage = "Failed to update application status.";
                            }
                        } catch (SQLException e) {
                            e.printStackTrace();
                            errorMessage = "Database error: " + e.getMessage();
                        } finally {
                            if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
                        }
                    } else {
                        errorMessage = "Invalid action.";
                    }
                }

                // Display success or error message
                if (successMessage != null) {
        %>
        <div class="alert alert-success">
            <p><%= successMessage %></p>
            <a href="viewApplications.jsp" class="btn secondary-cta-btn"><i class="fas fa-arrow-left"></i> Back to Applications</a>
        </div>
        <%
                } else if (errorMessage != null) {
        %>
        <div class="alert alert-error">
            <p><%= errorMessage %></p>
        </div>
        <%
                }

                // Fetch application details
                String sql = "SELECT * FROM bhel_training_application WHERE id = ?";
                if ("Trainee".equals(role)) {
                    sql += " AND user_id = (SELECT id FROM users WHERE username = ?)";
                }
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, appId);
                if ("Trainee".equals(role)) {
                    pstmt.setString(2, username);
                }
                rs = pstmt.executeQuery();

                if (rs.next()) {
                    String applicantName = rs.getString("applicant_name");
                    String instituteName = rs.getString("institute_name");
                    String trade = rs.getString("trade");
                    String rollNo = rs.getString("roll_no");
                    String batch = rs.getString("batch");
                    String yearOfStudy = rs.getString("year_of_study");
                    String dob = rs.getString("dob");
                    String guardianName = rs.getString("guardian_name");
                    String soDo = rs.getString("so_do");
                    String address = rs.getString("address");
                    String contactNumber = rs.getString("contact_number");
                    String aadhaarNumber = rs.getString("aadhaar_number");
                    String trainingRequired = rs.getString("training_required");
                    String trainingProgram = rs.getString("training_program");
                    String trainingPeriod = rs.getString("training_period");
                    double trainingFee = rs.getDouble("training_fee");
                    String subCaste = rs.getString("sub_caste");
                    String email = rs.getString("email");
                    String gender = rs.getString("gender");
                    String status = rs.getString("status");
                    String appliedDate = rs.getString("applied_date");
                    String aadhaarPath = rs.getString("aadhaar_path");
                    String instituteLetterPath = rs.getString("institute_letter_path");
                    String photoPath = rs.getString("photo_path");
                    String collegeIdPath = rs.getString("college_id_path");

                    // Check if required documents are uploaded
                    boolean documentsUploaded = (aadhaarPath != null && !aadhaarPath.trim().isEmpty()) &&
                                               (instituteLetterPath != null && !instituteLetterPath.trim().isEmpty());
        %>
        <div class="content">
            <div class="section-header">
                <h2>Application Overview</h2>
                <a href="viewApplications.jsp" class="btn secondary-cta-btn"><i class="fas fa-arrow-left"></i> Back to Applications</a>
            </div>
            <div class="details-grid">
                <div class="details-card">
                    <div class="category">
                        <h3>Personal Information</h3>
                        <div class="detail-item"><i class="fas fa-id-badge"></i><strong>Application ID:</strong> <%= appId %></div>
                        <div class="detail-item"><i class="fas fa-user"></i><strong>Applicant Name:</strong> <%= applicantName %></div>
                        <div class="detail-item"><i class="fas fa-calendar"></i><strong>Date of Birth:</strong> <%= dob %></div>
                        <div class="detail-item"><i class="fas fa-user-shield"></i><strong>Guardian's Name:</strong> <%= guardianName %></div>
                        <div class="detail-item"><i class="fas fa-users"></i><strong>S/o, D/o, W/o:</strong> <%= soDo != null ? soDo : "N/A" %></div>
                        <div class="detail-item"><i class="fas fa-venus-mars"></i><strong>Gender:</strong> <%= gender %></div>
                    </div>
                    <div class="category">
                        <h3>Contact Information</h3>
                        <div class="detail-item"><i class="fas fa-map-marker-alt"></i><strong>Address:</strong> <%= address %></div>
                        <div class="detail-item"><i class="fas fa-phone"></i><strong>Contact Number:</strong> <%= contactNumber %></div>
                        <div class="detail-item"><i class="fas fa-id-card"></i><strong>Aadhaar Number:</strong> <%= aadhaarNumber %></div>
                        <div class="detail-item"><i class="fas fa-envelope"></i><strong>Email:</strong> <%= email %></div>
                    </div>
                </div>
                <div class="details-card">
                    <div class="category">
                        <h3>Academic Information</h3>
                        <div class="detail-item"><i class="fas fa-university"></i><strong>Institute Name:</strong> <%= instituteName %></div>
                        <div class="detail-item"><i class="fas fa-graduation-cap"></i><strong>Trade:</strong> <%= trade %></div>
                        <div class="detail-item"><i class="fas fa-id-card-alt"></i><strong>Roll No:</strong> <%= rollNo %></div>
                        <div class="detail-item"><i class="fas fa-users-cog"></i><strong>Batch:</strong> <%= batch %></div>
                        <div class="detail-item"><i class="fas fa-calendar-alt"></i><strong>Year of Study:</strong> <%= yearOfStudy %></div>
                        <div class="detail-item"><i class="fas fa-users"></i><strong>Sub Caste:</strong> <%= subCaste %></div>
                    </div>
                    <div class="category">
                        <h3>Training Information</h3>
                        <div class="detail-item"><i class="fas fa-book"></i><strong>Training Required:</strong> <%= trainingRequired %></div>
                        <div class="detail-item"><i class="fas fa-chalkboard-teacher"></i><strong>Training Program:</strong> <%= trainingProgram %></div>
                        <div class="detail-item"><i class="fas fa-clock"></i><strong>Training Period:</strong> <%= trainingPeriod %></div>
                        <div class="detail-item"><i class="fas fa-money-bill"></i><strong>Training Fee:</strong> ₹<%= String.format("%.2f", trainingFee) %></div>
                        <div class="detail-item"><i class="fas fa-info-circle"></i><strong>Status:</strong> <span class="status-box <%= status.equalsIgnoreCase("pending") ? "status-pending" : status.equalsIgnoreCase("approved") ? "status-approved" : "status-rejected" %>"><%= status %></span></div>
                        <div class="detail-item"><i class="fas fa-calendar-check"></i><strong>Applied Date:</strong> <%= appliedDate %></div>
                    </div>
                </div>
            </div>

            <div class="section-header">
                <h2>Uploaded Documents</h2>
            </div>
            <div class="documents-card">
                <div class="card-list">
                    <div class="card">
                        <span>Aadhaar</span>
                        <p>
                            <% if (aadhaarPath != null && !aadhaarPath.trim().isEmpty()) { %>
                            <span class="status-box status-approved"><i class="fas fa-check-circle"></i> Uploaded</span>
                            <a href="<%= aadhaarPath %>" target="_blank" class="view-doc-btn">View Document</a>
                            <% } else { %>
                            <span class="status-box status-rejected"><i class="fas fa-exclamation-circle"></i> Not Uploaded</span>
                            <% } %>
                        </p>
                    </div>
                    <div class="card">
                        <span>Institute Letter</span>
                        <p>
                            <% if (instituteLetterPath != null && !instituteLetterPath.trim().isEmpty()) { %>
                            <span class="status-box status-approved"><i class="fas fa-check-circle"></i> Uploaded</span>
                            <a href="<%= instituteLetterPath %>" target="_blank" class="view-doc-btn">View Document</a>
                            <% } else { %>
                            <span class="status-box status-rejected"><i class="fas fa-exclamation-circle"></i> Not Uploaded</span>
                            <% } %>
                        </p>
                    </div>
                    <div class="card">
                        <span>Photo</span>
                        <p>
                            <% if (photoPath != null && !photoPath.trim().isEmpty()) { %>
                            <span class="status-box status-approved"><i class="fas fa-check-circle"></i> Uploaded</span>
                            <a href="<%= photoPath %>" target="_blank" class="view-doc-btn">View Document</a>
                            <% } else { %>
                            <span class="status-box status-rejected"><i class="fas fa-exclamation-circle"></i> Not Uploaded</span>
                            <% } %>
                        </p>
                    </div>
                    <div class="card">
                        <span>College ID</span>
                        <p>
                            <% if (collegeIdPath != null && !collegeIdPath.trim().isEmpty()) { %>
                            <span class="status-box status-approved"><i class="fas fa-check-circle"></i> Uploaded</span>
                            <a href="<%= collegeIdPath %>" target="_blank" class="view-doc-btn">View Document</a>
                            <% } else { %>
                            <span class="status-box status-rejected"><i class="fas fa-exclamation-circle"></i> Not Uploaded</span>
                            <% } %>
                        </p>
                    </div>
                </div>
            </div>

            <% if ("pending".equalsIgnoreCase(status) && "Admin".equals(role)) { %>
                <% if (documentsUploaded) { %>
                <div class="section-header">
                    <h2>Take Action</h2>
                </div>
                <div class="action-card">
                    <div class="action-grid">
                        <form action="viewApplicationDetails.jsp?appId=<%= appId %>" method="post">
                            <input type="hidden" name="action" value="Approve">
                            <button type="submit" class="btn cta-btn">Approve Application</button>
                        </form>
                        <form action="viewApplicationDetails.jsp?appId=<%= appId %>" method="post">
                            <input type="hidden" name="action" value="Reject">
                            <button type="submit" class="btn secondary-cta-btn">Reject Application</button>
                        </form>
                    </div>
                </div>
                <% } else { %>
                <div class="alert alert-info">
                    <p>Awaiting Documents: Please upload all required documents (Aadhaar and Institute Letter) before taking action.</p>
                </div>
                <% } %>
            <% } %>
        </div>
        <%
                } else {
        %>
        <div class="alert alert-error">
            <p>Application not found or you do not have permission to view it.</p>
            <a href="viewApplications.jsp" class="btn secondary-cta-btn"><i class="fas fa-arrow-left"></i> Back to Applications</a>
        </div>
        <%
                }
            } catch (SQLException e) {
                e.printStackTrace();
                if (e.getSQLState().equals("42S02")) {
        %>
        <div class="alert alert-error">
            <p>Error: Database table missing. Please ensure all tables are created.</p>
        </div>
        <%
                } else {
        %>
        <div class="alert alert-error">
            <p>Error: Unable to load application details. Please try again later.</p>
        </div>
        <%
                }
            } catch (Exception e) {
                e.printStackTrace();
        %>
        <div class="alert alert-error">
            <p>Error: Unable to load application details. Please try again later.</p>
        </div>
        <%
            } finally {
                if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
                if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
            }
        %>
    </div>
    <%@ include file="footer.jsp" %>
</body>
</html>