<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="utils.DBConnection, java.sql.*" %>
<%
    response.setContentType("application/json");
    String username = (String) session.getAttribute("username");
    if (username == null) {
        out.print("{\"success\":false,\"message\":\"Not logged in\"}");
        return;
    }

    String id = request.getParameter("id");
    try (Connection conn = DBConnection.getConnection();
         PreparedStatement pstmt = conn.prepareStatement("DELETE FROM notifications WHERE id = ?")) {
        pstmt.setInt(1, Integer.parseInt(id));
        pstmt.executeUpdate();
        out.print("{\"success\":true}");
    } catch (SQLException e) {
        out.print("{\"success\":false,\"message\":\"" + e.getMessage() + "\"}");
    }
%>