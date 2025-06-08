<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="utils.DBConnection, java.sql.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>View Applications - BHEL HRDC</title>
    <link rel="stylesheet" href="style.css">
    <style>
        /* Search Bar Styles */
       .search-container {
           display: flex;
           align-items: center;
           margin: 20px auto;
           max-width: 800px;
           background: #fff;
           border-radius: 10px;
           box-shadow: 0 6px 16px rgba(0, 0, 0, 0.15);
           overflow: hidden;
           transition: box-shadow 0.3s ease, transform 0.2s ease;
       }

       .search-container:hover {
           box-shadow: 0 8px 20px rgba(0, 0, 0, 0.2);
           transform: translateY(-2px);
       }

       .search-filter {
           flex: 0 0 140px;
           border: none;
           padding: 12px 16px;
           background-color: #f7fafc;
           border-right: 1px solid #e2e8f0;
           font-family: 'Roboto', Arial, sans-serif;
           font-size: 1em;
           color: #2d3748;
           border-radius: 10px 0 0 10px;
           transition: background-color 0.3s, border-color 0.3s;
       }

       .search-filter:focus {
           outline: none;
           background-color: #e6fffa;
           border-color: #d69e2e;
       }

       .search-input {
           flex: 1;
           border: none;
           padding: 12px 16px;
           font-family: 'Roboto', Arial, sans-serif;
           font-size: 1em;
           color: #2d3748;
           background-color: #fff;
           outline: none;
           transition: background-color 0.3s, border-color 0.3s;
       }

       .search-input:focus {
           background-color: #e6fffa;
           border-color: #d69e2e;
       }

       .search-button {
           background-color: #2c7a7b;
           border: none;
           padding: 12px 20px;
           cursor: pointer;
           display: flex;
           align-items: center;
           justify-content: center;
           border-radius: 0 10px 10px 0;
           transition: background-color 0.3s, transform 0.2s;
       }

       .search-button:hover {
           background-color: #4fd1c5;
           transform: scale(1.05);
       }

       .search-button::after {
           content: "🔍";
           font-size: 1.1em;
           color: #fff;
       }
       
       
      
       
        /* Responsive Design for Search Bar */
        @media (max-width: 768px) {
            .search-container {
                flex-direction: column;
                max-width: 100%;
                margin: 10px auto;
                border-radius: 8px;
            }

            .search-filter {
                width: 100%;
                border-radius: 8px 8px 0 0;
                border-right: none;
                border-bottom: 1px solid #e2e8f0;
                padding: 10px 16px;
            }

            .search-input {
                width: 100%;
                border-radius: 0;
                padding: 10px 16px;
            }

            .search-button {
                width: 100%;
                border-radius: 0 0 8px 8px;
                padding: 10px;
            }
        }

        @media (max-width: 480px) {
            .search-container {
                margin: 5px auto;
            }

            .search-filter, .search-input, .search-button {
                padding: 8px 12px;
                font-size: 0.95em;
            }
        }
    </style>
   
</head>
<body>
    <jsp:include page="navbar.jsp" />
   <%  String username = (String) session.getAttribute("username");
            String role = (String) session.getAttribute("role");%>
    
    <div class="container">
        <div class="hero">
            <div class="hero-content">
                <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
                <h1>View Applications - BHEL HRDC</h1>
                <p>Review and manage training applications for BHEL HRDC.</p>
            </div>
        </div>
        <%
           
            
            if (username == null || role == null) {
                response.sendRedirect("traineeLogin.jsp");
                return;
            }

            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            String errorMessage = null;

            // Get search and filter parameters (for Admin/Trainer only)
            String searchTerm = request.getParameter("search");
            String statusFilter = request.getParameter("status");
            if (searchTerm == null) searchTerm = "";
            if (statusFilter == null) statusFilter = "all";

            try {
                conn = DBConnection.getConnection();

      // Build the SQL query with search and filter conditions
String sql = "";
String baseSql = "SELECT a.id, a.applicant_name, a.training_required, a.status, ts.schedule_id, ts.progress, s.start_date, s.end_date, " +
                "a.aadhaar_path, a.institute_letter_path, a.photo_path, a.college_id_path " +
                "FROM bhel_training_application a " +
                "LEFT JOIN trainee_schedules ts ON a.id = ts.application_id " +
                "LEFT JOIN training_schedules s ON ts.schedule_id = s.id ";
String whereClause = "";
String orderByClause = " ORDER BY CASE " +
                       "WHEN LOWER(a.status) = 'pending' AND a.aadhaar_path IS NOT NULL AND a.institute_letter_path IS NOT NULL THEN 1 " +
                       "WHEN LOWER(a.status) = 'pending' AND (a.aadhaar_path IS NULL OR a.institute_letter_path IS NULL) THEN 2 " +
                       "WHEN LOWER(a.status) = 'Approved' THEN 3 " +
                       "WHEN LOWER(a.status) = 'Rejected' THEN 4 " +
                       "ELSE 5 END, a.id DESC";

if ("Trainee".equals(role)) {
    if (username == null || username.trim().isEmpty()) {
        throw new SQLException("Username is null or empty for Trainee role");
    }
    whereClause = "WHERE a.user_id = (SELECT id FROM users WHERE username = ?) ";
    sql = baseSql + whereClause + orderByClause;
    pstmt = conn.prepareStatement(sql);
    pstmt.setString(1, username);
} else if ("Admin".equals(role) || "Trainer".equals(role)) {
    if (!searchTerm.trim().isEmpty()) {
        whereClause = "WHERE (a.applicant_name LIKE ? OR a.training_required LIKE ?) ";
    }
    if (!"all".equals(statusFilter) && !"pending".equals(statusFilter) && 
        !"Approved".equals(statusFilter) && !"Rejected".equals(statusFilter)) {
        throw new IllegalArgumentException("Invalid status filter: " + statusFilter);
    }
    if (!"all".equals(statusFilter)) {
        whereClause += (whereClause.isEmpty() ? "WHERE " : "AND ") + "a.status = ? ";
    }
    sql = baseSql + whereClause + orderByClause;
    pstmt = conn.prepareStatement(sql);
    int paramIndex = 1;
    if (!searchTerm.trim().isEmpty()) {
        pstmt.setString(paramIndex++, "%" + searchTerm + "%");
        pstmt.setString(paramIndex++, "%" + searchTerm + "%");
    }
    if (!"all".equals(statusFilter)) {
        pstmt.setString(paramIndex++, statusFilter);
    }
}

rs = pstmt.executeQuery();
%>
        <!-- Search Bar with Filter (only for Admin/Trainer) -->
        <% if ("Admin".equals(role) || "Trainer".equals(role)) { %>
        <form action="viewApplications.jsp" method="get" class="search-container" onsubmit="event.preventDefault(); filterApplications();">
            <select id="statusFilter" name="status" class="search-filter" onchange="filterApplications()">
                <option value="all" <%= "all".equals(statusFilter) ? "selected" : "" %>>All Statuses</option>
                <option value="Approved" <%= "Approved".equals(statusFilter) ? "selected" : "" %>>Approved</option>
                <option value="Rejected" <%= "Rejected".equals(statusFilter) ? "selected" : "" %>>Rejected</option>
                <option value="pending" <%= "pending".equals(statusFilter) ? "selected" : "" %>>Pending</option>
            </select>
            <input type="text" id="searchInput" name="search" class="search-input" placeholder="Search by Applicant Name or Training Type" value="<%= searchTerm %>" oninput="filterApplications()">
            <button type="submit" class="btn cta-btn search-button" aria-label="Search"></button>
        </form>
        <% } %>
        <!-- Display error message if any -->
        <% String error = request.getParameter("error"); %>
        <% if (error != null) { %>
        <div class="alert alert-error" aria-live="polite">
            <p>Error: <%= error %></p>
        </div>
        <% } %>
        
        <table class="dashboard-table content">
            <thead>
                <tr>
                    <th>Application ID</th>
                    <th>Applicant Name</th>
                    <th>Training Type</th>
                    <th>Status</th>
                    <th>Schedule</th>
                    <th>Progress</th>
                    <% if ("Admin".equals(role)|| "Trainer".equals(role)) { %>
                    <th>Action</th>
                    <% } %>
                    <% if ("Trainee".equals(role)) { %>
                    <th>View</th>
                    <% } %>
                    <th>Print</th>
                </tr>
            </thead>
            <tbody>
                <%
                    boolean hasApplications = false;
                    while (rs.next()) {
                        hasApplications = true;
                        int appId = rs.getInt("id");
                        String applicantName = rs.getString("applicant_name");
                        String trainingRequired = rs.getString("training_required");
                        String status = rs.getString("status");
                        String scheduleId = rs.getString("schedule_id");
                        String progress = rs.getString("progress");
                        String scheduleDetails = scheduleId != null ? 
                            "From " + rs.getDate("start_date") + " to " + rs.getDate("end_date") : 
                            "Not Assigned";
                        boolean needsSchedule = "Approved".equals(status) && scheduleId == null;

                        // Check if required documents are uploaded (for Admin view)
                        boolean documentsUploaded = false;
                        if ("Admin".equals(role) || "Trainer".equals(role)|| "Trainee".equals(role)) {
                            String aadhaarPath = rs.getString("aadhaar_path");
                            String instituteLetterPath = rs.getString("institute_letter_path");
                            documentsUploaded = (aadhaarPath != null && !aadhaarPath.trim().isEmpty()) && 
                                                (instituteLetterPath != null && !instituteLetterPath.trim().isEmpty());
                        }
                %>
                <tr>
    <td><%= appId %></td>
    <td><%= applicantName %></td>
    <td><%= trainingRequired %></td>
    <td>
        <% if ("pending".equals(status) && !documentsUploaded) { %>
        <span class="alert alert-info" style="display: inline-block; padding: 2px 6px; font-size: 0.8em; margin-top: 18px;">Awaiting<br>Documents</span>
        <% } else { %>
        <span class="status-box <%= status.equals("Approved") ? "status-approved" : status.equals("Rejected") ? "status-rejected" : "status-pending" %>">
            <%= status %>
        </span>
        <%}%>
    </td>
    <td> <% if (needsSchedule &&( "Admin".equals(role) || "Trainer".equals(role))) { %>
        <span class="alert alert-info" style="display: inline-block; padding: 5px 10px; font-size: 0.9em;">Needs Assignment</span>
        <form action="AssignScheduleServlet" method="post" style="display:inline;">
            <input type="hidden" name="appId" value="<%= appId %>">
            <select name="scheduleId" required aria-required="true">
                <option value="">Select Schedule</option>
                <%
                    PreparedStatement scheduleStmt = null;
                    ResultSet scheduleRs = null;
                    try {
                        String scheduleSql = "SELECT id, training_type, start_date, end_date " +
                                            "FROM training_schedules " +
                                            "WHERE start_date >= CURDATE()";
                        scheduleStmt = conn.prepareStatement(scheduleSql);
                        scheduleRs = scheduleStmt.executeQuery();
                        while (scheduleRs.next()) {
                            int schedId = scheduleRs.getInt("id");
                            String trainingType = scheduleRs.getString("training_type");
                            String startDate = scheduleRs.getDate("start_date").toString();
                            String endDate = scheduleRs.getDate("end_date").toString();
                %>
                <option value="<%= schedId %>"><%= trainingType %> (<%= startDate %> to <%= endDate %>)</option>
                <%
                        }
                    } catch (SQLException e) {
                        e.printStackTrace();
                %>
                <option value="">Error loading schedules</option>
                <%
                    } finally {
                        if (scheduleRs != null) scheduleRs.close();
                        if (scheduleStmt != null) scheduleStmt.close();
                    }
                %>
            </select>
            <button type="submit" class="btn cta-btn">Assign</button>
        </form>
        <% } else if (scheduleId != null) { %>
        <%= scheduleDetails %>
        <% } else { %>
        <span class="status-box " >
            Not Assigned
        </span>
        <% } %>
    </td>
    <td><%= progress != null ? progress : "N/A" %></td>
    <% if ("Admin".equals(role)|| "Trainer".equals(role)|| "Trainee".equals(role)) { %>
    <td>
        <a href="viewApplicationDetails.jsp?appId=<%= appId %>" class="btn view-btn">View</a>
    </td>
    <% } %>
    
    <td>
        <a href="printApplication?appId=<%= appId %>" class="btn print-btn">Print</a>
    </td>
</tr>
                <%
                    }
                %>
                <tr id="noResultsRow" style="display: <%= hasApplications ? "none" : "" %>;">
                    <td colspan="<%= "Admin".equals(role) ? 8 : ("Trainer".equals(role) ? 7 : 6) %>">No applications found.</td>
                </tr>
            </tbody>
        </table>
        <%
            } catch (SQLException e) {
                e.printStackTrace();
                if (e.getSQLState().equals("42S02")) {
        %>
        <div class="alert alert-error" aria-live="polite">
            <p>Error: Database table missing. Please ensure all tables are created.</p>
        </div>
        <%
                } else {
        %>
        <div class="alert alert-error" aria-live="polite">
            <p>Error: Unable to load applications. Please try again later.</p>
        </div>
        <%
                }
            } catch (Exception e) {
                e.printStackTrace();
        %>
        <div class="alert alert-error" aria-live="polite">
            <p>Error: Unable to load applications. Please try again later.</p>
        </div>
        <%
            } finally {
                if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
                if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
            }
        %>
    </div>
   <script>
    <% if ("Admin".equals(role) || "Trainer".equals(role)) { %>
    function filterApplications() {
        // Get filter elements and values
        const searchInput = document.getElementById("searchInput")?.value.toLowerCase() || '';
        const statusFilter = document.getElementById("statusFilter")?.value.toLowerCase() || 'all';
        const rows = document.querySelectorAll(".dashboard-table tbody tr");
        
        // Separate data rows from "no results" row
        const dataRows = Array.from(rows).filter(row => row.id !== "noResultsRow");
        const noResultsRow = document.getElementById("noResultsRow");
        
        if (dataRows.length === 0) {
            noResultsRow.style.display = "";
            return;
        }

        // Process each application row
        const processedRows = dataRows.map(row => {
            if (row.cells.length < 4) return null;
            
            // Extract row data
            const cells = row.cells;
            const applicantName = cells[1].textContent.toLowerCase();
            const trainingType = cells[2].textContent.toLowerCase();
            const statusCell = cells[3];
            
            // Determine status with priority handling
            let status, statusOrder;
            const statusText = statusCell.textContent.toLowerCase().trim();
            const statusBox = statusCell.querySelector('.status-box');
            
            if (statusBox) {
                status = statusBox.textContent.trim().toLowerCase();
            } else if (statusText.includes('awaiting')) {
                status = 'awaiting';
            } else {
                status = statusText;
            }
            
            // Assign priority order
            if (status === 'pending') {
                statusOrder = 1; // Highest priority
            } else if (status === 'awaiting') {
                statusOrder = 2; // Second priority
            } else if (status === 'approved') {
                statusOrder = 3;
            } else if (status === 'rejected') {
                statusOrder = 4;
            } else {
                statusOrder = 5;
            }

            // Check documents status for Admin
            const actionCellIndex = <%= "Admin".equals(role) ? 6 : 6 %>;
            const hasDocuments = <%= "Admin".equals(role) %> ? 
                !cells[actionCellIndex]?.textContent.toLowerCase().includes('awaiting documents') : true;

            // Search matching logic
            const matchesSearch = searchInput === '' || 
                               applicantName.includes(searchInput) || 
                               trainingType.includes(searchInput);
                               
            const startsWithSearch = applicantName.startsWith(searchInput) || 
                                   trainingType.startsWith(searchInput);

            // Status filter matching
            const matchesStatus = statusFilter === 'all' || 
                               (statusFilter === 'pending' && (status === 'pending' || status === 'awaiting')) || 
                               status === statusFilter;

            return {
                row,
                matches: matchesSearch && matchesStatus,
                statusOrder,
                startsWith: startsWithSearch,
                applicantName,
                hasDocuments
            };
        }).filter(Boolean);

        // Sort rows with custom priority
        processedRows.sort((a, b) => {
            // 1. Status priority (pending > awaiting > approved > rejected)
            if (a.statusOrder !== b.statusOrder) return a.statusOrder - b.statusOrder;
            
            // 2. Documents status (only for Admin)
            <% if ("Admin".equals(role)) { %>
            if (a.hasDocuments !== b.hasDocuments) return a.hasDocuments ? -1 : 1;
            <% } %>
            
            // 3. Exact match at start of name/training
            if (a.startsWith !== b.startsWith) return a.startsWith ? -1 : 1;
            
            // 4. Alphabetical by applicant name
            return a.applicantName.localeCompare(b.applicantName);
        });

        // Update DOM efficiently
        const tbody = document.querySelector(".dashboard-table tbody");
        const fragment = document.createDocumentFragment();
        
        // Hide all rows first
        dataRows.forEach(row => row.style.display = "none");
        
        // Add visible rows in sorted order
        const visibleRows = processedRows.filter(row => row.matches);
        visibleRows.forEach(row => {
            row.row.style.display = "";
            fragment.appendChild(row.row);
        });
        
        // Handle empty results
        noResultsRow.style.display = visibleRows.length ? "none" : "";
        fragment.appendChild(noResultsRow);
        tbody.appendChild(fragment);

        // Debug output
        console.debug("Filter applied:", {
            searchTerm: searchInput,
            statusFilter: statusFilter,
            resultsCount: visibleRows.length,
            statusDistribution: visibleRows.reduce((acc, row) => {
                const status = row.row.cells[3].textContent.trim();
                acc[status] = (acc[status] || 0) + 1;
                return acc;
            }, {})
        });
    }

    // Initialize with event listeners
    document.addEventListener('DOMContentLoaded', () => {
        // Initial filter
        filterApplications();
        
        // Real-time filtering
        document.getElementById("searchInput").addEventListener('input', 
            debounce(filterApplications, 300));
            
        document.getElementById("statusFilter").addEventListener('change', filterApplications);
        
        // Debounce helper for search input
        function debounce(func, wait) {
            let timeout;
            return function() {
                const context = this, args = arguments;
                clearTimeout(timeout);
                timeout = setTimeout(() => func.apply(context, args), wait);
            };
        }
    });
    <% } %>
</script>
    <jsp:include page="footer.jsp" />
</body>
</html>