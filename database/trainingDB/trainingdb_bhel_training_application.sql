-- MySQL dump 10.13  Distrib 8.0.42, for Win64 (x86_64)
--
-- Host: localhost    Database: trainingdb
-- ------------------------------------------------------
-- Server version	8.0.42

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `bhel_training_application`
--

DROP TABLE IF EXISTS `bhel_training_application`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bhel_training_application` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `applicant_name` varchar(100) DEFAULT NULL,
  `institute_name` varchar(100) DEFAULT NULL,
  `trade` varchar(100) DEFAULT NULL,
  `roll_no` varchar(50) DEFAULT NULL,
  `batch` varchar(50) DEFAULT NULL,
  `year_of_study` varchar(10) DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `guardian_name` varchar(100) DEFAULT NULL,
  `address` text,
  `contact_number` varchar(15) DEFAULT NULL,
  `aadhaar_number` varchar(20) DEFAULT NULL,
  `training_required` varchar(100) DEFAULT NULL,
  `sub_caste` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `gender` varchar(10) DEFAULT NULL,
  `status` enum('pending','Approved','Rejected') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT 'pending',
  `training_program` enum('Diploma (6 Months)','Graduate (3 Years)','Graduate (4 Years)','Postgraduate') NOT NULL,
  `aadhaar_path` varchar(255) DEFAULT NULL,
  `training_period` varchar(20) DEFAULT NULL,
  `training_fee` decimal(10,2) DEFAULT NULL,
  `so_do` varchar(255) DEFAULT NULL,
  `institute_letter_path` varchar(255) DEFAULT NULL,
  `photo_path` varchar(255) DEFAULT NULL,
  `college_id_path` varchar(255) DEFAULT NULL,
  `applied_date` date NOT NULL DEFAULT '2025-01-01',
  `payment_status` enum('Pending','Paid','Overdue') DEFAULT 'Pending',
  `payment_date` date DEFAULT NULL,
  `discount` double DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `bhel_training_application_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bhel_training_application`
--

LOCK TABLES `bhel_training_application` WRITE;
/*!40000 ALTER TABLE `bhel_training_application` DISABLE KEYS */;
INSERT INTO `bhel_training_application` VALUES (1,3,'koushik','Dadi Institute of Engineering','btech','12','gtfgfhvb','1st Year','2005-05-30','kudirilla prem kumar','town kotha road,punja junction','9392148628','433434347777','internship','BCA','koushikkudirilla@gmail.com','Male','Approved','Diploma (6 Months)','uploads/koushikkudirilla_8714a6d7-f0cf-46a6-a55a-dd424c75d45c_monthly_report (2).pdf','6 months',2950.00,'kudirilla prem kumar','uploads/koushikkudirilla_c7d60105-2d0f-4a0e-a4a5-a73557e49ace_application_form_8.pdf','uploads/koushikkudirilla_9605bcec-61f1-4c50-97a3-f92298fdd8ca_WhatsApp Image 2025-03-28 at 16.19.34_cd470969.jpg','uploads/koushikkudirilla_20465b37-aa7c-4742-89c6-b002951bdd99_monthly_report (1).pdf','2025-06-05','Paid','2025-06-06',0),(2,7,'koushik','Dadi Institute of Engineering','btech','12','gtfgfhvb','1st Year','2005-05-30','kudirilla prem kumar','town kotha road,punja junction','9392148628','433434347777','internship','BCA','koushikkudirilla@gmail.com','Male','Approved','Graduate (4 Years)','uploads/koushik_kudirilla_8178e939-8e4b-4ea0-9a23-739335d27aaa_WhatsApp Image 2025-05-07 at 13.28.25_fc83fc35.jpg','1 month',2360.00,'kudirilla prem kumar','uploads/koushik_kudirilla_16c095a1-977d-401c-8a21-9040128f4946_receipt_appId_1.pdf','uploads/koushik_kudirilla_69a344a1-3751-4a3c-88d6-92fbacd73ba9_WhatsApp Image 2025-03-28 at 16.19.25_5d054e52.jpg','uploads/koushik_kudirilla_c84251dd-f8b6-4eaf-bcd7-228a3f0f4042_receipt_appId_1.pdf','2025-06-06','Paid','2025-06-06',0);
/*!40000 ALTER TABLE `bhel_training_application` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-06-08 21:06:18
