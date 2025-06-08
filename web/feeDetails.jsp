<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.text.NumberFormat, java.util.Locale, java.util.Date, java.text.SimpleDateFormat" %>
<%@ page import="utils.DBConnection" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fee Details - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <div class="container">
        <div class="hero" aria-label="Fee Details Header">
            <div class="hero-content">
                <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
                <h1>Fee Details</h1>
                <p>View and Manage Your Training Fees</p>
            </div>
        </div>
        <%
            String username = (String) session.getAttribute("username");
            String role = (String) session.getAttribute("role");
            String message = request.getParameter("message");
            String timestampStr = request.getParameter("timestamp");
            boolean showMessage = false;

            if (message != null && timestampStr != null) {
                try {
                    long timestamp = Long.parseLong(timestampStr);
                    long currentTime = System.currentTimeMillis();
                    long timeDiffSeconds = (currentTime - timestamp) / 1000;
                    long timeLimitSeconds = 2;

                    if (timeDiffSeconds <= timeLimitSeconds) {
                        showMessage = true;
                    }
                } catch (NumberFormatException e) {
                    // Invalid timestamp
                }
            }

            String error = request.getParameter("error");
            if (showMessage) {
        %>
        <div id="successMessage" class="alert alert-success">
            <p><%= message.replace("+", " ") %></p>
        </div>
        <script>
            setTimeout(function() {
                var messageDiv = document.getElementById("successMessage");
                if (messageDiv) {
                    messageDiv.style.display = "none";
                }
            }, 2000);
        </script>
        <%
            } else if (error != null) {
        %>
        <div id="successMessage" class="alert alert-error">
            <p><%= error.replace("+", " ") %></p>
        </div>
        <%
            }

            if (username == null || role == null || !"Trainee".equals(role)) {
                System.out.println("Unauthorized access attempt at " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
                response.sendRedirect("traineeLogin.jsp");
                return;
            }

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
               
                conn = DBConnection.getConnection();

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

                String sql = "SELECT training_program, training_period, training_fee" +
                            (hasPaymentStatus ? ", payment_status" : "") +
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
                double discount = hasDiscount ? rs.getDouble("discount") : 0.0;

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

                double discountedFee = totalFee - discount;
                double baseFee = totalFee - (serviceCharges + cgst + sgst);
                NumberFormat currencyFormat = NumberFormat.getCurrencyInstance(new Locale("en", "IN"));
        %>
        <div class="content">
            <h2>Fee Details for Application ID: <%= appId %></h2>
            <div id="successMessage" class="alert"></div>
            <div class="table-container">
                <table class="dashboard-table" aria-label="Fee Details">
                    <thead>
                        <tr>
                            <th>Training Program</th>
                            <th>Duration</th>
                            <th>Base Fee</th>
                            <th>Service Charges</th>
                            <th>CGST (9%)</th>
                            <th>SGST (9%)</th>
                            <th>Discount</th>
                            <th>Total Fee</th>
                            <% if (hasPaymentStatus) { %>
                            <th>Payment Status</th>
                            <% } %>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td data-label="Training Program"><%= trainingProgram %></td>
                            <td data-label="Duration"><%= trainingPeriod %></td>
                            <td data-label="Base Fee"><%= currencyFormat.format(baseFee) %></td>
                            <td data-label="Service Charges"><%= currencyFormat.format(serviceCharges) %></td>
                            <td data-label="CGST (9%)"><%= currencyFormat.format(cgst) %></td>
                            <td data-label="SGST (9%)"><%= currencyFormat.format(sgst) %></td>
                            <td data-label="Discount"><%= currencyFormat.format(discount) %></td>
                            <td data-label="Total Fee" class="total"><%= currencyFormat.format(discountedFee) %></td>
                            <% if (hasPaymentStatus) { %>
                            <td data-label="Payment Status"><span class="status-box <%= paymentStatus.toLowerCase().equalsIgnoreCase("pending")? "status-pending": "status-approved"%>"><%= paymentStatus %></span></td>
                            <% } %>
                        </tr>
                    </tbody>
                </table>
            </div>
            <div>
                <% if (hasPaymentStatus && "Pending".equals(paymentStatus)) { %>
                    <button class="btn view-btn" style="transform: none" onclick="initiatePayment(<%= appId %>)">Pay Now</button>
                <% } %>
                <% if (hasPaymentStatus && "Paid".equals(paymentStatus)) { %>
                    <button class="btn view-btn" style="transform: none" onclick="downloadReceipt(<%= appId %>)">Download Receipt</button>
                <% } %>
                <a href="traineeDashboard.jsp" class="btn secondary-cta-btn" style="transform: none">Back to Dashboard</a>
            </div>
            <h2>Fee Payment History</h2>
            <div class="table-container">
                <%
                    sql = "SELECT id, training_program, training_fee" +
                          (hasPaymentStatus ? ", payment_status" : "") +
                          (hasPaymentDate ? ", payment_date" : "") +
                          " FROM bhel_training_application " +
                          "WHERE user_id = (SELECT id FROM users WHERE username = ?) AND status = 'Approved'";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, username);
                    rs = pstmt.executeQuery();
                %>
                <table class="dashboard-table" aria-label="Fee Payment History">
                    <thead>
                        <tr>
                            <th>Application ID</th>
                            <th>Training Program</th>
                            <th>Total Fee</th>
                            <% if (hasPaymentStatus) { %>
                            <th>Payment Status</th>
                            <% } %>
                            <% if (hasPaymentDate) { %>
                            <th>Payment Date</th>
                            <% } %>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            boolean hasHistory = false;
                            while (rs.next()) {
                                hasHistory = true;
                                int historyAppId = rs.getInt("id");
                                String historyProgram = rs.getString("training_program");
                                double historyFee = rs.getDouble("training_fee");
                                String historyStatus = hasPaymentStatus ? rs.getString("payment_status") : "N/A";
                                Date paymentDate = hasPaymentDate ? rs.getDate("payment_date") : null;
                        %>
                        <tr>
                            <td data-label="Application ID"><%= historyAppId %></td>
                            <td data-label="Training Program"><%= historyProgram %></td>
                            <td data-label="Total Fee"><%= currencyFormat.format(historyFee) %></td>
                            <% if (hasPaymentStatus) { %>
                            <td data-label="Payment Status"><span class="status-box  <%= historyStatus.toLowerCase().equalsIgnoreCase("pending")? "status-pending": "status-approved"%>"><%= historyStatus %></span></td>
                            <% } %>
                            <% if (hasPaymentDate) { %>
                            <td data-label="Payment Date"><%= paymentDate != null ? new SimpleDateFormat("dd-MM-yyyy").format(paymentDate) : "N/A" %></td>
                            <% } %>
                        </tr>
                        <%
                            }
                            if (!hasHistory) {
                        %>
                        <tr>
                            <td colspan="<%= (hasPaymentStatus && hasPaymentDate) ? 5 : (hasPaymentStatus ? 4 : 3) %>">No payment history available.</td>
                        </tr>
                        <%
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>
        <%
            } catch (SQLException e) {
                System.out.println("Database error at " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()) + ": " + e.getMessage());
        %>
        <div id="successMessage" class="alert alert-error">
            <p>Database error: <%= java.net.URLEncoder.encode(e.getMessage(), "UTF-8").replace("+", " ") %></p>
        </div>
        <%
            } catch (Exception e) {
                System.out.println("Server error at " + new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()) + ": " + e.getMessage());
        %>
        <div id="successMessage" class="alert alert-error">
            <p>Server error: <%= java.net.URLEncoder.encode(e.getMessage(), "UTF-8").replace("+", " ") %></p>
        </div>
        <%
            } finally {
                if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
                if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
            }
        %>
    </div>
    <jsp:include page="footer.jsp" />
    <script>
        function downloadReceipt(appId) {
            const successMessage = document.getElementById("successMessage");
            successMessage.style.display = "block";
            successMessage.innerText = "Downloading receipt for Application ID: " + appId;
            successMessage.classList.remove("alert-error");
            successMessage.classList.add("alert-success");
            setTimeout(() => {
                window.location.href = "generateReceipt?appId=" + appId;
                setTimeout(() => {
                    successMessage.style.display = "none";
                    successMessage.innerText = "";
                }, 500);
            }, 2000);
        }

        function initiatePayment(appId) {
            const successMessage = document.getElementById("successMessage");
            successMessage.style.display = "none";

            if (!confirmPayment()) {
                return;
            }

            fetch("<%= request.getContextPath() %>/processPaymentServlet?appId=" + appId, { method: "POST" })
                .then(response => {
                    if (!response.ok) {
                        throw new Error("HTTP error " + response.status);
                    }
                    const contentType = response.headers.get("content-type");
                    if (contentType && contentType.includes("application/json")) {
                        return response.json();
                    } else {
                        throw new Error("Response is not JSON");
                    }
                })
                .then(data => {
                    if (data.success) {
                        successMessage.style.display = "block";
                        successMessage.innerText = "Payment successful! A schedule has been assigned.";
                        successMessage.classList.remove("alert-error");
                        successMessage.classList.add("alert-success");
                        setTimeout(() => {
                            window.location.reload();
                        }, 2000);
                    } else {
                        successMessage.style.display = "block";
                        successMessage.innerText = "Payment failed: " + data.message;
                        successMessage.classList.remove("alert-success");
                        successMessage.classList.add("alert-error");
                    }
                })
                .catch(error => {
                    successMessage.style.display = "block";
                    successMessage.innerText = "Error processing payment: " + error.message;
                    successMessage.classList.remove("alert-success");
                    successMessage.classList.add("alert-error");
                });
        }

        function confirmPayment() {
            return true;
        }
    </script>
</body>
</html>