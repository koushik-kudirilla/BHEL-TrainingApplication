
# Training-Management-System

A web-based training management application developed as part of an academic project. Built using Java EE technologies, this application facilitates the automation of training request handling, approvals, and scheduling workflows.

---

## Technologies Used

- **Java (JSP / Servlets)**
- **JDBC (MySQL)**
- **HTML5 / CSS3 / JavaScript**
- **NetBeans IDE**
- **Tomcat Server (Localhost)**
- **MySQL Database**

---

##Project Structure

```
Training-Management-System/
├── build/                           # Compiled files (ignored by Git)
│   ├── empty/
│   ├── generated-sources/
│   └── web/
│       ├── META-INF/
│       │   └── context.xml          # Deployment context file (ignored)
│       ├── uploads/                 # Temporary uploaded files (ignored)
│       └── WEB-INF/
│           └── lib/                 # Runtime libraries (ignored)
├── nbproject/                       # NetBeans project configuration (ignored)
├── src/                             # Java source files
│   ├── controller/                  # Servlet controllers
│   ├── dao/                         # Data Access Objects
│   └── model/                       # JavaBeans or business logic classes
├── web/                             # Web application resources
│   ├── META-INF/
│   │   └── context.xml              # Deployment context file 
│   ├── WEB-INF/
│   │   └── lib/                     # Runtime libraries (JAR files)
│   ├── uploads/                     # User-uploaded files (ignored)
│   ├── css/                         # Stylesheets
│   ├── js/                          # JavaScript files
│   └── images/                      # Image assets
├── .gitignore                       # Git ignore rules
└── README.md                        # Project documentation 
```

---

## Features

- Admin login & user management  
- Employee request submission for training programs  
- Role-based dashboard (Admin, Coordinator, HOD, Training Officer, etc.)  
- Approval workflow system (multi-level: HOD â†’ TO â†’ Principal)  
- Email notification integration (optional)  
- Secure file upload system  
- Training schedule and attendance log sheet management

---

## Security Practices

This project incorporates several security techniques:

- **Authentication & Session Management**
- **Authorization Checks (Role-based)**
- **Password Handling with Salting and Hashing (Partially implemented)**
- **File Upload Path Sanitization**
- **SQL Injection Prevention (via PreparedStatements)**

---

## Setup Instructions

1. **Clone the Repository**

   ```bash
   git clone https://github.com/koushik-kudirilla/Training-Management-System.git
   cd Training-Management-System
   ```

2. **Open in NetBeans**
   - Go to NetBeans > `File` > `Open Project`
   - Select the `Training-Management-System` directory

3. **Configure the Database**
   - Create a MySQL database named `training_db`
   - Import the SQL dump file or manually create required tables

4. **Edit DB Credentials**
   - Go to your DAO classes (e.g., `DBConnection.java`) and set:
     ```java
     String url = "jdbc:mysql://localhost:3306/training_db";
     String user = "root";
     String pass = "your_password";
     ```

5. **Run the App**
   - Right-click the project `Run`
   - App will be deployed to `http://localhost:8080/BHEL-TrainingApplication`

---

## Notes

- All build, temp, and IDE-specific files are excluded from version control using `.gitignore`
- Uploads and sensitive config files are also ignored to protect user data
- Make sure to adjust paths for deployment in a production environment

---

## Authors

- **Koushik** Developer, UI Designer, Integrator  


---

## License

This project is for academic/demo purposes. For real-world deployment or reuse, proper security audits and enhancements are recommended.
