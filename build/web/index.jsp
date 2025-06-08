
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BHEL HRDC - Training Portal</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
</head>
<body>
    <%@ include file="navbar.jsp" %>
    
    <div class="container">
        <div class="hero">
        <div class="hero-content">
            <img src="images/bhel_logo.png" alt="BHEL Logo" class="hero-logo">
            <h1>BHEL HRDC Training Portal</h1>
            <p>Transforming Futures with Cutting-Edge Industrial Training</p>
        </div>
    </div>
        <div class="content">
            <p class="intro">
                The Bharat Heavy Electricals Limited - Human Resource Development Centre (BHEL HRDC) Training Management System (TMS) empowers aspiring engineers by simplifying the application and management of industrial training and internships. Join us to gain hands-on experience and advance your career.
            </p>

            <div class="two-column">
                <div class="column">
                    <h2>Resources</h2>
                    <div class="card-list">
                        <div class="card">
                            <a href="faqs.jsp">Explore FAQs</a>
                            <p>Find answers to common questions about our training programs.</p>
                        </div>
                        <div class="card">
                            <a href="guidelines.jsp">Training Guidelines</a>
                            <p>Understand the requirements and process for internships at BHEL HRDC.</p>
                        </div>
                        <div class="card">
                            <a href="availableDates.jsp">Check Training Dates</a>
                            <p>View available slots for training at BHEL HRDC.</p>
                        </div>
                    </div>
                </div>
                <div class="column">
                    <h2>Application Workflow</h2>
                    <div class="card-list">
                        <div class="card">
                            <span>1. Register</span>
                            <p>Create an account via <a href="register.jsp">Trainee Registration</a>.</p>
                        </div>
                        <div class="card">
                            <span>2. Verify Email</span>
                            <p>Confirm your email using the verification link sent to you.</p>
                        </div>
                        <div class="card">
                            <span>3. Submit Application</span>
                            <p>Complete the <a href="applicationForm.jsp">Application Form</a> with required documents.</p>
                        </div>
                        <div class="card">
                            <span>4. Upload Documents</span>
                            <p>Provide institute letter (<a href="instituteLetterFormat.pdf">download format</a>) and, if applicable, BHEL employee ID proof (<a href="sampleEmployeeId.pdf">sample</a>).</p>
                        </div>
                        <div class="card note">
                            <span>Note</span>
                            <p>Registration does not guarantee a training seat. You’ll receive an email regarding your application status.</p>
                        </div>
                    </div>
                </div>
            </div>

            <p class="contact-info">
                If the available training dates don’t suit your schedule, email <a href="mailto:hrdc@bhel.com">hrdc@bhel.com</a> (Attn: Mr. S. Rao, Sr. Manager, Training) or visit HRDC, BHEL Hyderabad, on any working day to start your training.
            </p>

            <h2>Get Started</h2>
            <div class="cta-grid">
                <a href="register.jsp" class="btn cta-btn">Register as Trainee</a>
                <a href="traineeLogin.jsp" class="btn cta-btn">Trainee Login</a>
                <a href="employeeLogin.jsp" class="btn cta-btn">Employee Login</a>
            </div>
        </div>
    </div>
    <jsp:include page="footer.jsp" />
</body>
</html>
