CREATE DATABASE  IF NOT EXISTS `nutrition_app` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `nutrition_app`;
-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: nutrition_app
-- ------------------------------------------------------
-- Server version	9.4.0

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
-- Table structure for table `dessert_menus`
--

DROP TABLE IF EXISTS `dessert_menus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dessert_menus` (
  `id` int NOT NULL AUTO_INCREMENT,
  `dessert_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `calories` float DEFAULT NULL,
  `protein_g` float DEFAULT NULL,
  `carbs_g` float DEFAULT NULL,
  `fat_g` float DEFAULT NULL,
  `fiber_g` float DEFAULT NULL,
  `sugar_g` float DEFAULT NULL,
  `iron` float DEFAULT NULL,
  `vitamin_c` float DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dessert_menus`
--

LOCK TABLES `dessert_menus` WRITE;
/*!40000 ALTER TABLE `dessert_menus` DISABLE KEYS */;
INSERT INTO `dessert_menus` VALUES (1,'Pie, apple','dessert',296,2.7,37.55,15.28,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(2,'Apple pie filling','dessert',100,0.1,26.1,0.1,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(3,'Cake or cupcake, apple','dessert',376,2.41,52.52,17.5,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(4,'Banana pudding','dessert',160,2.57,28,4.26,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(5,'Cake or cupcake, banana','dessert',379,2.47,53.07,17.51,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(6,'Pie, banana cream','dessert',284,2.42,32.35,16.17,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(7,'Mango, dried, sweetened','dessert',1340,2.45,78.6,1.18,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(8,'Pie, strawberry','dessert',289,2.88,44.22,11.6,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(9,'Cake or cupcake, strawberry','dessert',326,2.22,50.25,12.89,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(10,'Cake, strawberry shortcake','dessert',214,3.31,40.09,4.73,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(11,'Ice creams, strawberry','dessert',803,3.2,27.6,8.4,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(12,'Strawberries, frozen, sweetened, sliced','dessert',402,0.53,25.9,0.13,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(13,'Pie, blueberry','dessert',300,2.82,37.95,15.52,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(14,'Blueberries, dried, sweetened','dessert',1330,2.5,80,2.5,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(15,'Blueberries, frozen, sweetened','dessert',355,0.4,22,0.13,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(16,'Blueberry pie filling','dessert',181,0.41,44.38,0.2,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(17,'Pie fillings, blueberry, canned','dessert',757,0.41,44.4,0.2,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(18,'Pie, blueberry, commercially prepared','dessert',971,1.8,34.9,10,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(19,'Potato pancake','dessert',196,4.47,20.64,10.8,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(20,'Potato pancakes','dessert',268,6.08,27.8,14.8,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(21,'Sweet potato tots','dessert',191,2.26,37.3,9.35,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(22,'Bread, sweet potato','dessert',241,8.64,45.38,2.87,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(23,'Pie, sweet potato','dessert',269,4.96,41.08,9.75,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(24,'Sweet potato chips','dessert',529,2.92,56.54,32.19,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(25,'Sweet potato paste','dessert',305,0.49,75.14,0.34,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(26,'Sweet potato, candied','dessert',187,1.18,37.69,3.48,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(27,'Sweet potato, NFS','dessert',115,1.58,17.14,4.53,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(28,'Sweet potato tots, school','dessert',192,2.27,37.45,9.39,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(29,'Sweet potato, casserole or mashed','dessert',99,1.89,17.22,2.56,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(30,'Bread, sweet potato, toasted','dessert',265,9.5,49.87,3.15,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(31,'Sweet potato fries, frozen','dessert',192,2.27,37.45,9.39,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(32,'Sweet potato fries, NFS','dessert',192,2.27,37.45,9.39,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(33,'Sweet potato fries, school','dessert',192,2.27,37.45,9.39,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(34,'Sweet potato leaves, raw','dessert',175,2.49,8.82,0.51,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(35,'Sweet potato, canned, mashed','dessert',101,1.98,23.2,0.2,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(36,'Sweet potato, cooked, as ingredient','dessert',82,1.65,18.05,0.4,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06'),(37,'Onions, sweet, raw','dessert',32,0.8,7.55,0.08,NULL,NULL,NULL,NULL,'2026-02-26 17:03:06');
/*!40000 ALTER TABLE `dessert_menus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `drink_menus`
--

DROP TABLE IF EXISTS `drink_menus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `drink_menus` (
  `id` int NOT NULL AUTO_INCREMENT,
  `drink_type_id` int NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `calories` decimal(6,2) DEFAULT '0.00',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `sugar_g` decimal(6,2) DEFAULT NULL,
  `protein_g` decimal(6,2) DEFAULT NULL,
  `iron` decimal(6,2) DEFAULT NULL,
  `vitamin_c` decimal(6,2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_drink_type_id` (`drink_type_id`),
  CONSTRAINT `drink_menus_ibfk_1` FOREIGN KEY (`drink_type_id`) REFERENCES `drink_types` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `drink_menus`
--

LOCK TABLES `drink_menus` WRITE;
/*!40000 ALTER TABLE `drink_menus` DISABLE KEYS */;
INSERT INTO `drink_menus` VALUES (1,3,'Brewed Coffee',3.00,'2026-02-26 17:12:03',0.00,0.30,0.00,0.00),(2,3,'Caffè Latte',70.00,'2026-02-26 17:12:03',9.00,6.00,0.00,0.00),(3,3,'Caffè Mocha (Without Whipped Cream)',110.00,'2026-02-26 17:12:03',17.00,7.00,10.00,0.00),(4,3,'Vanilla Latte (Or Other Flavoured Latte)',100.00,'2026-02-26 17:12:03',18.00,6.00,0.00,0.00),(5,3,'Caffè Americano',5.00,'2026-02-26 17:12:03',0.00,0.40,0.00,0.00),(6,3,'Cappuccino',50.00,'2026-02-26 17:12:03',7.00,5.00,0.00,0.00),(7,3,'Espresso',5.00,'2026-02-26 17:12:03',0.00,0.40,0.00,0.00),(8,2,'Skinny Latte (Any Flavour)',60.00,'2026-02-26 17:12:03',8.00,6.00,0.00,0.00),(9,3,'Caramel Macchiato',100.00,'2026-02-26 17:12:03',15.00,6.00,0.00,0.00),(10,3,'White Chocolate Mocha (Without Whipped Cream)',180.00,'2026-02-26 17:12:03',29.00,7.00,0.00,0.00),(11,3,'Hot Chocolate (Without Whipped Cream)',130.00,'2026-02-26 17:12:03',23.00,7.00,10.00,0.00),(12,3,'Caramel Apple Spice (Without Whipped Cream)',140.00,'2026-02-26 17:12:03',33.00,0.00,0.00,0.00),(13,1,'Tazo® Tea',0.00,'2026-02-26 17:12:03',0.00,0.00,0.00,0.00),(14,1,'Tazo® Chai Tea Latte',100.00,'2026-02-26 17:12:03',21.00,4.00,0.00,0.00),(15,1,'Tazo® Green Tea Latte',130.00,'2026-02-26 17:12:03',25.00,7.00,2.00,4.00),(16,1,'Tazo® Full-Leaf Tea Latte',80.00,'2026-02-26 17:12:03',16.00,4.00,0.00,0.00),(17,1,'Tazo® Full-Leaf Red Tea Latte (Vanilla Rooibos)',80.00,'2026-02-26 17:12:03',16.00,4.00,0.00,0.00),(18,3,'Iced Brewed Coffee (With Classic Syrup)',60.00,'2026-02-26 17:12:03',15.00,0.20,0.00,0.00),(19,3,'Iced Brewed Coffee (With Milk & Classic Syrup)',80.00,'2026-02-26 17:12:03',18.00,2.00,0.00,0.00),(20,3,'Shaken Iced Tazo® Tea (With Classic Syrup)',60.00,'2026-02-26 17:12:03',15.00,0.00,6.00,0.00),(21,3,'Shaken Iced Tazo® Tea Lemonade (With Classic Syrup)',100.00,'2026-02-26 17:12:03',24.00,0.10,0.00,10.00),(22,1,'Banana Chocolate Smoothie',280.00,'2026-02-26 17:12:03',34.00,20.00,0.00,15.00),(23,1,'Orange Mango Banana Smoothie',260.00,'2026-02-26 17:12:03',37.00,16.00,30.00,80.00),(24,1,'Strawberry Banana Smoothie',290.00,'2026-02-26 17:12:03',41.00,16.00,8.00,100.00),(25,3,'Coffee',160.00,'2026-02-26 17:12:03',36.00,3.00,10.00,0.00),(26,3,'Mocha (Without Whipped Cream)',180.00,'2026-02-26 17:12:03',40.00,3.00,8.00,0.00),(27,3,'Caramel (Without Whipped Cream)',180.00,'2026-02-26 17:12:03',41.00,3.00,0.00,0.00),(28,3,'Java Chip (Without Whipped Cream)',220.00,'2026-02-26 17:12:03',44.00,4.00,20.00,0.00),(29,3,'Mocha',110.00,'2026-02-26 17:12:03',23.00,3.00,6.00,0.00),(30,3,'Caramel',100.00,'2026-02-26 17:12:03',23.00,3.00,0.00,0.00),(31,3,'Java Chip',150.00,'2026-02-26 17:12:03',27.00,4.00,20.00,0.00),(32,3,'Strawberries & Crème (Without Whipped Cream)',170.00,'2026-02-26 17:12:03',38.00,3.00,2.00,6.00),(33,3,'Vanilla Bean (Without Whipped Cream)',170.00,'2026-02-26 17:12:03',38.00,4.00,0.00,0.00);
/*!40000 ALTER TABLE `drink_menus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `drink_types`
--

DROP TABLE IF EXISTS `drink_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `drink_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_drink_type_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `drink_types`
--

LOCK TABLES `drink_types` WRITE;
/*!40000 ALTER TABLE `drink_types` DISABLE KEYS */;
INSERT INTO `drink_types` VALUES (2,'เครื่องดื่มลดน้ำหนัก'),(3,'เครื่องดื่มเพิ่มพลังงาน'),(1,'เครื่องดื่มเพื่อสุขภาพ');
/*!40000 ALTER TABLE `drink_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `food_categories`
--

DROP TABLE IF EXISTS `food_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `food_categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `food_type_id` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `idx_food_categories_food_type` (`food_type_id`),
  CONSTRAINT `fk_food_categories_food_type` FOREIGN KEY (`food_type_id`) REFERENCES `food_types` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `food_categories`
--

LOCK TABLES `food_categories` WRITE;
/*!40000 ALTER TABLE `food_categories` DISABLE KEYS */;
INSERT INTO `food_categories` VALUES (4,'อาหารครบ5หมู่',1),(5,'อาหารลดน้ำหนัก',1),(6,'อาหารสร้างกล้ามเนื้อ',1),(7,'อาหารครบ5หมู่',2),(8,'อาหารลดน้ำหนัก',2),(9,'อาหารบำรุงสุขภาพ',2),(10,'อาหารครบ5หมู่',3),(11,'อาหารลดน้ำหนัก',3),(12,'อาหารให้พลังงานสูง',3);
/*!40000 ALTER TABLE `food_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `food_menus`
--

DROP TABLE IF EXISTS `food_menus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `food_menus` (
  `id` int NOT NULL AUTO_INCREMENT,
  `food_type_id` int NOT NULL,
  `category_id` int NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `calories` float DEFAULT NULL,
  `protein` float DEFAULT NULL,
  `carbs` float DEFAULT NULL,
  `fat` float DEFAULT NULL,
  `is_dessert` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_food_menus_food_type_id` (`food_type_id`),
  KEY `ix_food_menus_category_id` (`category_id`),
  CONSTRAINT `food_menus_ibfk_1` FOREIGN KEY (`food_type_id`) REFERENCES `food_types` (`id`),
  CONSTRAINT `food_menus_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `food_categories` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=164 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `food_menus`
--

LOCK TABLES `food_menus` WRITE;
/*!40000 ALTER TABLE `food_menus` DISABLE KEYS */;
INSERT INTO `food_menus` VALUES (1,2,8,'Apple, raw',61,0.17,14.8,0.15,0),(2,3,10,'Apple, dried',243,0.93,65.89,0.32,0),(3,3,10,'Crisp, apple',215,2.81,30.18,9.59,0),(4,3,11,'Apple, baked',113,0.32,22.7,3.08,0),(5,2,8,'Apple cider',46,0.1,11.3,0.13,0),(6,3,10,'Cobbler, apple',217,2.05,33.56,8.66,0),(7,3,12,'Croissants, apple',1060,7.4,37.1,8.7,0),(8,3,10,'Strudel, apple',281,1.96,37.18,14.08,0),(9,2,8,'Apple juice, 100%',48,0.09,11.34,0.25,0),(10,2,9,'Apple salad with dressing',180,1.45,12.2,14.24,0),(11,3,10,'Fruit butters, apple',173,0.39,42.5,0.3,0),(12,2,7,'Rose-apples, raw',105,0.6,5.7,0.3,0),(13,2,7,'Carrots, raw, salad with apples',181,0.85,8.59,16.02,0),(14,3,10,'Banana, baked',161,0.82,32.43,3.21,0),(15,3,11,'Banana, raw',97,0.74,22.71,0.28,0),(16,3,12,'Banana chips',519,2.3,58.4,33.6,0),(17,2,8,'Banana nectar',74,0.26,18.01,0.13,0),(18,3,10,'Banana split',199,2.42,32.59,6.88,0),(19,3,10,'Bananas, raw',371,1.09,22.8,0.33,0),(20,3,11,'Bananas, overripe, raw',85,0.73,20.1,0.22,0),(21,2,8,'Melon, banana (Navajo)',90,0.84,4.06,0.2,0),(22,2,8,'Pepper, banana, raw',27,1.66,5.35,0.45,0),(23,2,8,'Peppers, banana, raw',27,1.66,5.35,0.45,0),(24,3,12,'Snacks, banana chips',519,2.3,58.4,33.6,0),(25,2,8,'Orange, raw',50,0.92,11.78,0.14,0),(26,3,10,'Marmalade, orange',246,0.3,66.3,0,0),(27,2,8,'Orange Blossom',98,0.57,9.32,0.26,0),(28,3,10,'Orange chicken',262,14.46,22.46,12.68,0),(29,3,10,'Sherbet, orange',144,1.1,30.4,2,0),(30,2,8,'Orange, canned, NFS',46,0.6,11.82,0.04,0),(31,2,7,'Beverages, carbonated, orange',201,0,12.3,0,0),(32,3,12,'Orange peel, raw',405,1.5,25,0.2,0),(33,2,8,'Oranges, raw, Florida',46,0.7,11.5,0.21,0),(34,2,8,'Oranges, raw, navels',47,0.91,11.8,0.15,0),(35,2,7,'Oranges, raw, with peel',262,1.3,15.5,0.3,0),(36,2,8,'Tomatoes, orange, raw',67,1.16,3.18,0.19,0),(37,2,8,'Grapes, raw',83,0.9,19.4,0.2,0),(38,2,8,'Grape juice, 100%',66,0.18,15.73,0.28,0),(39,2,8,'Grape leaves, canned',69,4.27,11.7,1.97,0),(40,2,7,'Grape leaves, raw',390,5.6,17.3,2.12,0),(41,2,7,'Grapes, muscadine, raw',238,0.81,13.9,0.47,0),(42,2,8,'Tomatoes, grape, raw',27,0.83,5.51,0.63,0),(43,2,7,'Beverages, carbonated, grape soda',180,0,11.2,0,0),(44,2,8,'Beverages, grape drink, canned',61,0,15.7,0,0),(45,2,8,'Grape juice drink, light',23,0.06,5.51,0.1,0),(46,2,9,'Grape leaves stuffed with rice',168,2.28,13.88,11.95,0),(47,2,7,'Beverages, grape juice drink, canned',237,0,14.6,0,0),(48,2,7,'Beverages, OCEAN SPRAY, Cran Grape',224,0.21,13.2,0,0),(49,2,8,'Grape juice, 100%, with calcium added',62,0.37,14.77,0.13,0),(50,2,9,'Stuffed grape leaves with beef and rice',228,8.15,11.3,17.03,0),(51,2,9,'Stuffed grape leaves with lamb and rice',271,8.17,11.89,21.52,0),(52,2,8,'Mango, raw',60,0.82,14.98,0.38,0),(53,2,8,'Mango, canned',65,0.62,16.22,0.3,0),(54,2,8,'Mango, frozen',60,0.82,14.98,0.38,0),(55,2,8,'Mango nectar',51,0.11,13.12,0.06,0),(56,3,10,'Mango, dried',319,2.45,78.58,1.18,0),(57,2,8,'Mangos, raw',60,0.82,15,0.38,0),(58,2,8,'Mango nectar, canned',51,0.11,13.1,0.06,0),(59,2,8,'Beverages, V8 SPLASH Smoothies, Peach Mango',37,1.22,7.76,0,0),(60,2,9,'Yogurt, Greek, 2% fat, mango, CHOBANI',93,7.64,11.8,1.69,0),(61,2,8,'Beverages, V8 SPLASH Juice Drinks, Mango Peach',33,0,8.23,0,0),(62,2,8,'Beverages, V8 V-FUSION Juices, Peach Mango',49,0.41,11.4,0,0),(63,2,7,'Fruit juice smoothie, NAKED JUICE, MIGHTY MANGO',262,0.42,15,0,0),(64,2,8,'Salsa, red, homemade',34,1.44,6.74,0.19,0),(65,2,8,'Pear, raw',59,0.37,15.18,0.15,0),(66,2,8,'Pear nectar',60,0.11,15.76,0.01,0),(67,3,10,'Pear, dried',262,1.87,69.7,0.63,0),(68,2,8,'Pears, raw',57,0.36,15.2,0.14,0),(69,2,8,'Pear, Asian, raw',42,0.5,10.65,0.23,0),(70,2,8,'Pear, canned, NFS',52,0.2,13.47,0.06,0),(71,2,7,'Pears, asian, raw',176,0.5,10.6,0.23,0),(72,2,7,'Pears, raw, bartlett',238,0.38,15.1,0.16,0),(73,2,7,'Prickly pears, raw',172,0.73,9.57,0.51,0),(74,2,8,'Pear, canned, juice pack',45,0.23,11.79,0.07,0),(75,3,12,'Pears, dried, sulfured, uncooked',1100,1.87,69.7,0.63,0),(76,2,8,'Pears, raw, red anjou',62,0.33,14.9,0.14,0),(77,2,8,'Strawberries, raw',36,0.64,7.96,0.22,0),(78,3,11,'Strawberries, canned',92,0.56,23.53,0.26,0),(79,2,8,'Strawberries, frozen',35,0.43,9.13,0.11,0),(80,3,12,'Toppings, strawberry',1060,0.2,66.3,0.1,0),(81,2,7,'Guavas, strawberry, raw',289,0.58,17.4,0.6,0),(82,3,10,'McDONALD\'S, Strawberry Sundae',158,3.19,28.1,3.95,0),(83,2,8,'Strawberry juice, 100%',23,0.42,5.17,0.14,0),(84,2,8,'Strawberry milk, NFS',65,3.2,8.54,2.06,0),(85,2,9,'Strawberry milk, whole',86,3.03,11.79,2.97,0),(86,3,12,'Fast foods, sundae, strawberry',732,4.09,29.2,5.13,0),(87,2,9,'Kefir, lowfat, strawberry, LIFEWAY',62,3.39,10.2,0.9,0),(88,2,9,'SILK Strawberry soy yogurt',94,2.35,18.2,1.18,0),(89,2,8,'Blueberries, raw',64,0.7,14.57,0.31,0),(90,2,8,'Blueberries, frozen',51,0.42,12.17,0.64,0),(91,3,10,'Blueberries, dried',317,2.5,80,2.5,0),(92,2,8,'Blueberry juice',42,0.46,9.47,0.2,0),(93,3,12,'Muffins, blueberry, toaster-type',1310,4.6,53.3,9.5,0),(94,2,8,'SILK Blueberry soy yogurt',88,2.35,17.1,1.18,0),(95,2,9,'Yogurt, Greek, Blueberry, CHOBANI',82,7.23,12.8,0.24,0),(96,2,9,'Potato patty',171,3.89,13.49,11.32,0),(97,2,8,'Soup, potato',90,1.51,10.53,4.71,0),(98,2,9,'Stewed potatoes',103,1.99,16.26,3.39,0),(99,3,10,'Potato, NFS',126,1.87,20.45,4.25,0),(100,3,12,'Bread, potato',1120,12.5,47.1,3.13,0),(101,2,9,'Gnocchi, potato',135,2.44,17.2,6.33,0),(102,3,10,'Potato flour',357,6.9,83.1,0.34,0),(103,2,9,'Soup, potato with meat',109,3.78,8.81,6.43,0),(104,3,10,'Potato tots, NFS',237,1.9,24.4,15.46,0),(105,2,9,'Potato tots, school',166,2.02,19.34,9.16,0),(106,3,10,'Potato, boiled, NFS',126,1.87,20.45,4.25,0),(107,3,12,'Potato chips, NFS',532,6.39,53.83,33.98,0),(108,3,12,'Potato chips, plain',532,6.39,53.83,33.98,0),(109,3,12,'Potato chips, unsalted',537,6.25,59.66,30.3,0),(110,3,12,'Potato sticks, flavored',517,6.63,52.77,34.06,0),(111,2,8,'Tomatoes, raw',20,0.82,4.04,0.31,0),(112,2,7,'Guacamole with tomatoes',145,1.87,8.09,13.09,0),(113,2,8,'Soup, tomato',19,0.65,3.64,0.41,0),(114,2,7,'Tomatoes, scalloped',110,2.7,14.1,4.97,0),(115,2,7,'Tomato products, canned, sauce, with tomato tidbits',134,1.32,7.09,0.39,0),(116,3,10,'Sun-dried tomatoes',258,14.11,55.76,2.97,0),(117,2,8,'Tomatoes, red, ripe, canned, packed in tomato juice',16,0.79,3.47,0.25,0),(118,3,10,'Fried green tomatoes',216,3.68,21.78,12.84,0),(119,2,8,'Tomato juice cocktail',22,0.93,3.87,0.31,0),(120,2,9,'Rice, white, with tomatoes and/or tomato-based sauce, fat added',107,2,19.41,2.18,0),(121,2,8,'Tomatoes, canned, cooked',43,0.82,3.23,3.04,0),(122,2,8,'Tomatoes, fresh, cooked',50,1.08,4.71,3.42,0),(123,2,7,'Bacon and tomato dressing',326,1.8,2,35,0),(124,3,10,'Beans and rice, with tomatoes',137,4.7,21.9,3.46,0),(125,1,5,'Pork with chili and tomatoes',95,11.64,2.68,3.99,0),(126,2,8,'Soup, cream of tomato',70,1.21,6.39,4.68,0),(127,2,8,'Soup, tomato, canned',34,0.63,7.65,0.33,0),(128,2,8,'Stewed potatoes with tomatoes',87,1.71,12.89,3.29,0),(129,2,8,'Onions, raw',38,0.86,8.46,0.08,0),(130,3,10,'Bread, onion',238,8.81,44.32,2.95,0),(131,2,8,'Onions, green, raw',32,1.83,7.34,0.19,0),(132,2,8,'Onions, green, cooked',63,2.09,8.37,3.21,0),(133,2,8,'Onions, pearl, cooked',50,0.7,6.49,2.59,0),(134,2,7,'Onion dip, regular',346,2.15,3.92,35.77,0),(135,2,7,'Onion dip, light',166,2,11.87,12.36,0),(136,3,10,'Bread, onion, toasted',262,9.68,48.7,3.24,0),(137,3,10,'DENNY\'S, onion rings',385,5.29,41,22.2,0),(138,3,10,'Fried onion rings',352,4.19,39.94,19.82,0),(139,3,12,'Onion flavored rings',499,7.7,65.1,22.6,0),(140,2,8,'Onions, cooked, as ingredient',47,1.29,10.99,0.12,0),(141,3,10,'Onions, dehydrated flakes',349,8.95,83.3,0.46,0),(142,2,8,'Onions, for use on a sandwich',38,0.86,8.46,0.08,0),(143,2,8,'Onions, red, raw',44,0.94,9.93,0.1,0),(144,2,7,'Onions, welsh, raw',142,1.9,6.5,0.4,0),(145,2,8,'Onions, white, raw',35,0.89,7.68,0.13,0),(146,2,8,'Onions, yellow, raw',38,0.83,8.61,0.05,0),(147,2,7,'Garlic sauce',683,1.43,2.87,74.02,0),(148,3,10,'Garlic, cooked',142,6.58,28.03,0.38,0),(149,3,10,'Garlic, raw',143,6.62,28.2,0.38,0),(150,3,10,'Roll, garlic',309,10.84,51.92,6.44,0),(151,3,12,'Garlic bread, frozen',1460,8.36,41.7,16.6,0),(152,3,10,'Garlic bread, NFS',349,8.34,41.64,16.58,0),(153,3,10,'Garlic bread, from frozen',350,8.36,41.72,16.61,0),(154,3,12,'PIZZA HUT, breadstick, parmesan garlic',1430,12.2,44.5,12.9,0),(155,3,10,'Garlic bread, from fast food / restaurant',349,8.34,41.64,16.58,0),(156,3,10,'Garlic bread, with melted cheese, from frozen',343,10.36,36.86,17.1,0),(157,3,10,'Garlic bread, with parmesan cheese, from frozen',351,8.78,41.14,16.83,0),(158,1,4,'Shrimp in garlic sauce, Puerto Rican style',281,11.56,2.45,24.96,0),(159,3,10,'Garlic bread, with parmesan cheese, from fast food / restaurant',351,8.76,41.06,16.8,0),(160,3,10,'Garlic bread, with melted cheese, from fast food / restaurant',339,11.41,34.21,17.34,0),(161,3,12,'Fast foods, breadstick, soft, prepared with garlic and parmesan cheese',1430,12.2,44.5,12.9,0),(162,1,6,'HORMEL ALWAYS TENDER, Pork Loin Filets, Lemon Garlic-Flavored',492,17.8,1.79,4.16,0),(163,2,7,'Abiyuch, raw',290,1.5,17.6,0.1,0);
/*!40000 ALTER TABLE `food_menus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `food_types`
--

DROP TABLE IF EXISTS `food_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `food_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `food_types`
--

LOCK TABLES `food_types` WRITE;
/*!40000 ALTER TABLE `food_types` DISABLE KEYS */;
INSERT INTO `food_types` VALUES (1,'เมนูโปรตีน'),(2,'เมนูผักและผลไม้'),(3,'เมนูคาร์โบไฮเดรต');
/*!40000 ALTER TABLE `food_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `histories`
--

DROP TABLE IF EXISTS `histories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `histories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `data` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `histories_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `histories`
--

LOCK TABLES `histories` WRITE;
/*!40000 ALTER TABLE `histories` DISABLE KEYS */;
INSERT INTO `histories` VALUES (1,225,'ทดลองบันทึก','2026-02-14 09:54:50'),(2,23,'{\"recommendations\": [\"\\u0e23\\u0e30\\u0e1a\\u0e1a\\u0e41\\u0e19\\u0e30\\u0e19\\u0e33\\u0e16\\u0e39\\u0e01\\u0e1b\\u0e34\\u0e14\\u0e42\\u0e14\\u0e22\\u0e1c\\u0e39\\u0e49\\u0e43\\u0e0a\\u0e49\"], \"category\": null}','2026-02-14 06:03:25'),(3,23,'{\"recommendations\": [\"\\u0e23\\u0e30\\u0e1a\\u0e1a\\u0e41\\u0e19\\u0e30\\u0e19\\u0e33\\u0e16\\u0e39\\u0e01\\u0e1b\\u0e34\\u0e14\\u0e42\\u0e14\\u0e22\\u0e1c\\u0e39\\u0e49\\u0e43\\u0e0a\\u0e49\"], \"category\": null}','2026-02-14 06:11:30'),(4,23,'{\"recommendations\": [\"\\u0e23\\u0e30\\u0e1a\\u0e1a\\u0e41\\u0e19\\u0e30\\u0e19\\u0e33\\u0e16\\u0e39\\u0e01\\u0e1b\\u0e34\\u0e14\\u0e42\\u0e14\\u0e22\\u0e1c\\u0e39\\u0e49\\u0e43\\u0e0a\\u0e49\"], \"category\": null}','2026-02-14 06:17:41'),(5,23,'{\"recommendations\": [\"\\u0e23\\u0e30\\u0e1a\\u0e1a\\u0e41\\u0e19\\u0e30\\u0e19\\u0e33\\u0e16\\u0e39\\u0e01\\u0e1b\\u0e34\\u0e14\\u0e42\\u0e14\\u0e22\\u0e1c\\u0e39\\u0e49\\u0e43\\u0e0a\\u0e49\"], \"category\": null}','2026-02-14 06:47:35'),(6,23,'{\"personal\": {\"age\": 33, \"gender\": \"\\u0e0a\\u0e32\\u0e22\", \"weight\": 72.0, \"height\": 172.0}, \"calories\": {\"recommended_per_day\": 2000}, \"meal\": \"\\u0e01\\u0e25\\u0e32\\u0e07\\u0e27\\u0e31\\u0e19 + \\u0e40\\u0e22\\u0e47\\u0e19\", \"duration\": 4, \"category\": null}','2026-02-14 17:44:14'),(7,23,'{\"personal\": {\"age\": 32, \"gender\": \"\\u0e0a\\u0e32\\u0e22\", \"weight\": 72.0, \"height\": 172.0}, \"calories\": {\"recommended_per_day\": 2000}, \"meal\": \"\\u0e40\\u0e0a\\u0e49\\u0e32 + \\u0e01\\u0e25\\u0e32\\u0e07\\u0e27\\u0e31\\u0e19\", \"duration\": 3, \"category\": null}','2026-02-14 17:44:52'),(8,23,'{\"personal\": {\"age\": 21, \"gender\": \"\\u0e0a\\u0e32\\u0e22\", \"weight\": 57.0, \"height\": 176.0}, \"calories\": {\"recommended_per_day\": 2000}, \"meal\": \"\\u0e40\\u0e0a\\u0e49\\u0e32 + \\u0e01\\u0e25\\u0e32\\u0e07\\u0e27\\u0e31\\u0e19 + \\u0e40\\u0e22\\u0e47\\u0e19\", \"duration\": 7, \"category\": null}','2026-02-14 17:45:24'),(9,23,'{\"personal\": {\"age\": 54, \"gender\": \"\\u0e2b\\u0e0d\\u0e34\\u0e07\", \"weight\": 47.0, \"height\": 162.0}, \"calories\": {\"recommended_per_day\": 2000}, \"meal\": \"\\u0e40\\u0e0a\\u0e49\\u0e32 + \\u0e01\\u0e25\\u0e32\\u0e07\\u0e27\\u0e31\\u0e19 + \\u0e40\\u0e22\\u0e47\\u0e19\", \"duration\": 2, \"category\": null}','2026-02-14 17:53:33'),(10,23,'{\"personal\": {\"gender\": \"\\u0e2b\\u0e0d\\u0e34\\u0e07\", \"age\": \"31\", \"weight\": \"48\", \"height\": \"160\", \"status\": \"\\u0e1b\\u0e01\\u0e15\\u0e34\"}, \"calories\": {\"intake_per_day\": 1056, \"recommended_per_day\": 1397, \"diff_per_day\": -341, \"total_intake\": 3168, \"total_recommended\": 4191}, \"meal\": \"\\u0e40\\u0e0a\\u0e49\\u0e32 + \\u0e01\\u0e25\\u0e32\\u0e07\\u0e27\\u0e31\\u0e19\", \"duration\": 3}','2026-02-14 17:57:28'),(11,23,'{\"personal\": {\"gender\": \"\\u0e0a\\u0e32\\u0e22\", \"age\": \"21\", \"weight\": \"65\", \"height\": \"175\", \"status\": \"\\u0e1b\\u0e01\\u0e15\\u0e34\"}, \"calories\": {\"intake_per_day\": 790, \"recommended_per_day\": 1973, \"diff_per_day\": -1183, \"total_intake\": 3160, \"total_recommended\": 7892}, \"meal\": \"\\u0e40\\u0e0a\\u0e49\\u0e32 + \\u0e40\\u0e22\\u0e47\\u0e19\", \"duration\": 4}','2026-02-14 17:58:02'),(12,225,'{\"personal\": {\"gender\": \"\\u0e0a\\u0e32\\u0e22\", \"age\": \"25\", \"weight\": \"65\", \"height\": \"165\", \"status\": \"\\u0e1b\\u0e01\\u0e15\\u0e34\"}, \"calories\": {\"intake_per_day\": 1056, \"recommended_per_day\": 1874, \"diff_per_day\": -818, \"total_intake\": 3168, \"total_recommended\": 5622}, \"meal\": \"\\u0e40\\u0e0a\\u0e49\\u0e32 + \\u0e01\\u0e25\\u0e32\\u0e07\\u0e27\\u0e31\\u0e19\", \"duration\": 3}','2026-02-14 18:04:58'),(13,225,'{\"personal\": {\"gender\": \"\\u0e0a\\u0e32\\u0e22\", \"age\": \"19\", \"weight\": \"65\", \"height\": \"165\", \"status\": \"\\u0e1b\\u0e01\\u0e15\\u0e34\"}, \"calories\": {\"intake_per_day\": 790, \"recommended_per_day\": 1910, \"diff_per_day\": -1120, \"total_intake\": 3160, \"total_recommended\": 7640}, \"meal\": \"\\u0e40\\u0e0a\\u0e49\\u0e32 + \\u0e40\\u0e22\\u0e47\\u0e19\", \"duration\": 4}','2026-02-14 18:12:30'),(14,225,'{\"personal\": {\"gender\": \"\\u0e0a\\u0e32\\u0e22\", \"age\": \"9\", \"weight\": \"29\", \"height\": \"96\", \"status\": \"\\u0e2d\\u0e49\\u0e27\\u0e19\"}, \"calories\": {\"intake_per_day\": 790, \"recommended_per_day\": 1020, \"diff_per_day\": -230, \"total_intake\": 3160, \"total_recommended\": 4080}, \"meal\": \"\\u0e40\\u0e0a\\u0e49\\u0e32 + \\u0e40\\u0e22\\u0e47\\u0e19\", \"duration\": 4}','2026-02-14 18:20:57'),(15,225,'{\"personal\": {\"gender\": \"\\u0e0a\\u0e32\\u0e22\", \"age\": \"30\", \"weight\": \"76\", \"height\": \"166\", \"status\": \"\\u0e2d\\u0e27\\u0e1a\"}, \"calories\": {\"intake_per_day\": 1056, \"recommended_per_day\": 1983, \"diff_per_day\": -927, \"total_intake\": 3168, \"total_recommended\": 5949}, \"meal\": \"\\u0e40\\u0e0a\\u0e49\\u0e32 + \\u0e01\\u0e25\\u0e32\\u0e07\\u0e27\\u0e31\\u0e19\", \"duration\": 3}','2026-02-14 18:56:06'),(16,225,'{\"personal\": {\"gender\": \"\\u0e0a\\u0e32\\u0e22\", \"age\": \"30\", \"weight\": \"76\", \"height\": \"165\", \"status\": \"\\u0e2d\\u0e27\\u0e1a\"}, \"calories\": {\"intake_per_day\": 790, \"recommended_per_day\": 1976, \"diff_per_day\": -1186, \"total_intake\": 1580, \"total_recommended\": 3952}, \"meal\": \"\\u0e40\\u0e0a\\u0e49\\u0e32 + \\u0e40\\u0e22\\u0e47\\u0e19\", \"duration\": 2}','2026-02-14 18:57:08'),(22,1,'ทดลองบันทึก','2026-02-18 02:38:37'),(24,1,'{\"personal\": {\"gender\": \"ชาย\", \"age\": \"8\", \"weight\": \"26\", \"height\": \"93\"}, \"selectedType\": \"เมนูโปรตีน\", \"selectedCategory\": \"อาหารลดน้ำหนัก\", \"selectedMenu\": \"Pork with chili and tomatoes\", \"selectedDessert\": \"-\", \"selectedDrinkType\": \"เครื่องดื่มลดน้ำหนัก\", \"selectedDrinkMenu\": \"Skinny Latte (Any Flavour)\", \"meal\": \"เช้า + กลางวัน + เย็น\", \"duration\": 2, \"intake_per_day\": 0, \"total_intake\": 0, \"recommended_per_day\": 968, \"recommended_total\": 1936, \"status\": \"อ้วน\", \"description\": \"ควรได้รับ 968 kcal/วัน\\nแต่ได้รับเพียง 0 kcal/วัน\\n\\nรวม 2 วัน ควรได้รับ 1936 kcal\\nแต่ได้รับ 0 kcal\\n\\nแนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ\", \"summary\": \"มื้อ: เช้า + กลางวัน + เย็น\\nระยะเวลา: 2 วัน\\nรับ/วัน: 0 kcal\\nควรรับ/วัน: 968 kcal\\nรวมรับ: 0 kcal\\nรวมควรรับ: 1936 kcal\\nสถานะ: อ้วน\\nคำอธิบาย: ควรได้รับ 968 kcal/วัน\\nแต่ได้รับเพียง 0 kcal/วัน\\n\\nรวม 2 วัน ควรได้รับ 1936 kcal\\nแต่ได้รับ 0 kcal\\n\\nแนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ\\nเมนูที่เลือก: Pork with chili and tomatoes, -, Skinny Latte (Any Flavour)\"}','2026-02-28 21:23:45'),(25,1,'{\"personal\": {\"gender\": \"ชาย\", \"age\": \"29\", \"weight\": \"75\", \"height\": \"179\"}, \"selectedType\": \"เมนูคาร์โบไฮเดรต\", \"selectedCategory\": \"อาหารให้พลังงานสูง\", \"selectedMenu\": \"Toppings, strawberry\", \"selectedDessert\": \"Sweet potato, NFS\", \"selectedDrinkType\": \"เครื่องดื่มเพื่อสุขภาพ\", \"selectedDrinkMenu\": \"Tazo® Tea\", \"meal\": \"เช้า + กลางวัน + เย็น\", \"duration\": 3, \"intake_per_day\": 0, \"total_intake\": 0, \"recommended_per_day\": 2075, \"recommended_total\": 6225, \"status\": \"ปกติ\", \"description\": \"ควรได้รับ 2075 kcal/วัน\\nแต่ได้รับเพียง 0 kcal/วัน\\n\\nรวม 3 วัน ควรได้รับ 6225 kcal\\nแต่ได้รับ 0 kcal\\n\\nแนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ\", \"summary\": \"มื้อ: เช้า + กลางวัน + เย็น\\nระยะเวลา: 3 วัน\\nรับ/วัน: 0 kcal\\nควรรับ/วัน: 2075 kcal\\nรวมรับ: 0 kcal\\nรวมควรรับ: 6225 kcal\\nสถานะ: ปกติ\\nคำอธิบาย: ควรได้รับ 2075 kcal/วัน\\nแต่ได้รับเพียง 0 kcal/วัน\\n\\nรวม 3 วัน ควรได้รับ 6225 kcal\\nแต่ได้รับ 0 kcal\\n\\nแนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ\\nเมนูที่เลือก: Toppings, strawberry, Sweet potato, NFS, Tazo® Tea\"}','2026-02-28 22:57:41'),(26,1,'{\"personal\": {\"gender\": \"ชาย\", \"age\": \"29\", \"weight\": \"50\", \"height\": \"146\"}, \"selectedType\": \"เมนูคาร์โบไฮเดรต\", \"selectedCategory\": \"อาหารครบ5หมู่\", \"selectedMenu\": \"Bananas, raw\", \"selectedDessert\": \"Bread, sweet potato, toasted\", \"selectedDrinkType\": \"เครื่องดื่มลดน้ำหนัก\", \"selectedDrinkMenu\": \"Skinny Latte (Any Flavour)\", \"meal\": \"เช้า + เย็น\", \"duration\": 7, \"intake_per_day\": 0, \"total_intake\": 0, \"recommended_per_day\": 1527, \"recommended_total\": 10689, \"status\": \"ปกติ\", \"description\": \"ควรได้รับ 1527 kcal/วัน\\nแต่ได้รับเพียง 0 kcal/วัน\\n\\nรวม 7 วัน ควรได้รับ 10689 kcal\\nแต่ได้รับ 0 kcal\\n\\nแนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ\", \"summary\": \"มื้อ: เช้า + เย็น\\nระยะเวลา: 7 วัน\\nรับ/วัน: 0 kcal\\nควรรับ/วัน: 1527 kcal\\nรวมรับ: 0 kcal\\nรวมควรรับ: 10689 kcal\\nสถานะ: ปกติ\\nคำอธิบาย: ควรได้รับ 1527 kcal/วัน\\nแต่ได้รับเพียง 0 kcal/วัน\\n\\nรวม 7 วัน ควรได้รับ 10689 kcal\\nแต่ได้รับ 0 kcal\\n\\nแนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ\\nเมนูที่เลือก: Bananas, raw, Bread, sweet potato, toasted, Skinny Latte (Any Flavour)\"}','2026-02-28 23:12:34'),(27,7,'{\"personal\": {\"gender\": \"ชาย\", \"age\": \"31\", \"weight\": \"49\", \"height\": \"102\"}, \"selectedType\": \"เมนูโปรตีน\", \"selectedCategory\": \"อาหารลดน้ำหนัก\", \"selectedMenu\": \"Pork with chili and tomatoes\", \"selectedDessert\": \"-\", \"selectedDrinkType\": \"เครื่องดื่มเพิ่มพลังงาน\", \"selectedDrinkMenu\": \"Caramel Apple Spice (Without Whipped Cream)\", \"meal\": \"เช้า + กลางวัน + เย็น\", \"duration\": 5, \"intake_per_day\": 0, \"total_intake\": 0, \"recommended_per_day\": 1173, \"recommended_total\": 5865, \"status\": \"อ้วน\", \"description\": \"ควรได้รับ 1173 kcal/วัน\\nแต่ได้รับเพียง 0 kcal/วัน\\n\\nรวม 5 วัน ควรได้รับ 5865 kcal\\nแต่ได้รับ 0 kcal\\n\\nแนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ\", \"summary\": \"มื้อ: เช้า + กลางวัน + เย็น\\nระยะเวลา: 5 วัน\\nรับ/วัน: 0 kcal\\nควรรับ/วัน: 1173 kcal\\nรวมรับ: 0 kcal\\nรวมควรรับ: 5865 kcal\\nสถานะ: อ้วน\\nคำอธิบาย: ควรได้รับ 1173 kcal/วัน\\nแต่ได้รับเพียง 0 kcal/วัน\\n\\nรวม 5 วัน ควรได้รับ 5865 kcal\\nแต่ได้รับ 0 kcal\\n\\nแนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ\\nเมนูที่เลือก: Pork with chili and tomatoes, -, Caramel Apple Spice (Without Whipped Cream)\"}','2026-03-01 01:39:48'),(28,8,'{\"personal\": {\"gender\": \"ชาย\", \"age\": \"21\", \"weight\": \"65\", \"height\": \"170\"}, \"selectedType\": \"เมนูคาร์โบไฮเดรต\", \"selectedCategory\": \"อาหารให้พลังงานสูง\", \"selectedMenu\": \"Fast foods, sundae, strawberry\", \"selectedDessert\": \"Cake, strawberry shortcake\", \"selectedDrinkType\": \"เครื่องดื่มเพื่อสุขภาพ\", \"selectedDrinkMenu\": \"Orange Mango Banana Smoothie\", \"meal\": \"เช้า\", \"duration\": 5, \"intake_per_day\": 0, \"total_intake\": 0, \"recommended_per_day\": 1935, \"recommended_total\": 9675, \"status\": \"ปกติ\", \"description\": \"ควรได้รับ 1935 kcal/วัน\\nแต่ได้รับเพียง 0 kcal/วัน\\n\\nรวม 5 วัน ควรได้รับ 9675 kcal\\nแต่ได้รับ 0 kcal\\n\\nแนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ\", \"summary\": \"มื้อ: เช้า\\nระยะเวลา: 5 วัน\\nรับ/วัน: 0 kcal\\nควรรับ/วัน: 1935 kcal\\nรวมรับ: 0 kcal\\nรวมควรรับ: 9675 kcal\\nสถานะ: ปกติ\\nคำอธิบาย: ควรได้รับ 1935 kcal/วัน\\nแต่ได้รับเพียง 0 kcal/วัน\\n\\nรวม 5 วัน ควรได้รับ 9675 kcal\\nแต่ได้รับ 0 kcal\\n\\nแนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ\\nเมนูที่เลือก: Fast foods, sundae, strawberry, Cake, strawberry shortcake, Orange Mango Banana Smoothie\"}','2026-03-01 01:48:34'),(29,8,'{\"personal\": {\"gender\": \"ชาย\", \"age\": \"32\", \"weight\": \"52\", \"height\": \"144\"}, \"selectedType\": \"เมนูโปรตีน\", \"selectedCategory\": \"อาหารลดน้ำหนัก\", \"selectedMenu\": \"Pork with chili and tomatoes\", \"selectedDessert\": \"-\", \"selectedDrinkType\": \"เครื่องดื่มเพิ่มพลังงาน\", \"selectedDrinkMenu\": \"Caramel (Without Whipped Cream)\", \"meal\": \"เช้า + กลางวัน + เย็น\", \"duration\": 3, \"intake_per_day\": 0, \"total_intake\": 0, \"recommended_per_day\": 1518, \"recommended_total\": 4554, \"status\": \"อวบ\", \"description\": \"ควรได้รับ 1518 kcal/วัน\\nแต่ได้รับเพียง 0 kcal/วัน\\n\\nรวม 3 วัน ควรได้รับ 4554 kcal\\nแต่ได้รับ 0 kcal\\n\\nแนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ\", \"summary\": \"มื้อ: เช้า + กลางวัน + เย็น\\nระยะเวลา: 3 วัน\\nรับ/วัน: 0 kcal\\nควรรับ/วัน: 1518 kcal\\nรวมรับ: 0 kcal\\nรวมควรรับ: 4554 kcal\\nสถานะ: อวบ\\nคำอธิบาย: ควรได้รับ 1518 kcal/วัน\\nแต่ได้รับเพียง 0 kcal/วัน\\n\\nรวม 3 วัน ควรได้รับ 4554 kcal\\nแต่ได้รับ 0 kcal\\n\\nแนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ\\nเมนูที่เลือก: Pork with chili and tomatoes, -, Caramel (Without Whipped Cream)\"}','2026-03-01 01:54:04');
/*!40000 ALTER TABLE `histories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reports`
--

DROP TABLE IF EXISTS `reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reports` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `type` varchar(80) DEFAULT NULL,
  `detail` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reports`
--

LOCK TABLES `reports` WRITE;
/*!40000 ALTER TABLE `reports` DISABLE KEYS */;
INSERT INTO `reports` VALUES (1,225,'system','ระบบดี','2026-02-14 19:03:53'),(2,225,'system','ระบบดีมีคุณภาพ','2026-02-14 19:18:21'),(3,2,'system','asas','2026-02-15 19:19:43'),(4,6,'system','ระบบดีครับแจ๋วๆ','2026-02-25 07:00:49'),(5,8,'system','ไนท์ทำระบบดีมาก','2026-03-01 01:48:54');
/*!40000 ALTER TABLE `reports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `submissions`
--

DROP TABLE IF EXISTS `submissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `submissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `anon_id` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `anon_id` (`anon_id`),
  KEY `submissions_ibfk_1` (`user_id`),
  CONSTRAINT `submissions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `submissions`
--

LOCK TABLES `submissions` WRITE;
/*!40000 ALTER TABLE `submissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `submissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_selections`
--

DROP TABLE IF EXISTS `user_selections`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_selections` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `food_type_id` int DEFAULT NULL,
  `category_id` int DEFAULT NULL,
  `menu_id` int DEFAULT NULL,
  `dessert_menu_id` int DEFAULT NULL,
  `drink_type_id` int DEFAULT NULL,
  `drink_menu_id` int DEFAULT NULL,
  `meal` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `duration` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `food_type_id` (`food_type_id`),
  KEY `category_id` (`category_id`),
  KEY `menu_id` (`menu_id`),
  KEY `drink_type_id` (`drink_type_id`),
  KEY `drink_menu_id` (`drink_menu_id`),
  KEY `fk_user_selections_dessert` (`dessert_menu_id`),
  CONSTRAINT `fk_user_selections_dessert` FOREIGN KEY (`dessert_menu_id`) REFERENCES `dessert_menus` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `user_selections_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_selections_ibfk_2` FOREIGN KEY (`food_type_id`) REFERENCES `food_types` (`id`) ON DELETE SET NULL,
  CONSTRAINT `user_selections_ibfk_3` FOREIGN KEY (`category_id`) REFERENCES `food_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `user_selections_ibfk_4` FOREIGN KEY (`menu_id`) REFERENCES `food_menus` (`id`) ON DELETE SET NULL,
  CONSTRAINT `user_selections_ibfk_6` FOREIGN KEY (`drink_type_id`) REFERENCES `drink_types` (`id`) ON DELETE SET NULL,
  CONSTRAINT `user_selections_ibfk_7` FOREIGN KEY (`drink_menu_id`) REFERENCES `drink_menus` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_selections`
--

LOCK TABLES `user_selections` WRITE;
/*!40000 ALTER TABLE `user_selections` DISABLE KEYS */;
INSERT INTO `user_selections` VALUES (1,1,1,5,125,NULL,2,8,'เช้า + กลางวัน + เย็น',2,'2026-02-28 21:23:45'),(2,1,3,12,80,NULL,1,13,'เช้า + กลางวัน + เย็น',3,'2026-02-28 22:57:41'),(3,1,3,4,19,NULL,2,8,'เช้า + เย็น',7,'2026-02-28 23:12:34'),(4,7,1,5,125,NULL,3,12,'เช้า + กลางวัน + เย็น',5,'2026-03-01 01:39:48'),(5,8,3,12,86,NULL,1,23,'เช้า',5,'2026-03-01 01:48:34'),(6,8,1,5,125,NULL,3,27,'เช้า + กลางวัน + เย็น',3,'2026-03-01 01:54:04');
/*!40000 ALTER TABLE `user_selections` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_token` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `token_created_at` timestamp NULL DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `gender` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `age` int DEFAULT NULL,
  `weight` float DEFAULT NULL,
  `height` float DEFAULT NULL,
  `temp_password_hash` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `temp_password_expires_at` datetime DEFAULT NULL,
  `is_admin` tinyint(1) DEFAULT '0',
  `reset_token_expires_at` datetime DEFAULT NULL,
  `reset_token_hash` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reset_otp_hash` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reset_otp_expires_at` datetime DEFAULT NULL,
  `reset_otp_attempts` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'night','night1@gmail.com','scrypt:32768:8:1$8Chmo2GRQ87oV3nI$517b979b48b5d5e0b78b5c7c0cc2b182667ca75744b8ccf46becaf2738badaed317d351bd8c39443751d8da86d94ce762793c792e9a1efb303f0ea62986fefbe','bBerJXeNRSoDidezkFfiqv-sTK2zOmEdweMjtJF2jwc','2026-02-28 23:12:05','2026-02-16 02:02:43','ชาย',31,74,148,NULL,NULL,0,NULL,NULL,NULL,NULL,0),(2,'night12','night2@gmail.co','scrypt:32768:8:1$xKRWuo5o0sRKl7GI$ce9158ac8470c3c64447303366f44eb16332759225d6a69d89a13754804b8e765ed51245e22e863512ad53c9743cfe0ada23174935837f5a29f0ff650fc1d173','BbT7FtwsllQTbGXd2QGthUYU0dioEjntJW2KVpqqO7c','2026-02-15 19:19:11','2026-02-16 02:18:39','ชาย',10,27,98,NULL,NULL,0,NULL,NULL,NULL,NULL,0),(3,'nightty','nightty1@gmail.com','scrypt:32768:8:1$w4kZIEpyjgMCCDRm$1212ab734ce94819eedf379af5adf4399358e2367c4c574d3c7eeb51994776482c458f8ca37bcbfbe57a24b5b43560e4baf9ed7863df3f6175329ff48e2f9c01','I-2peEPsuAfUmMzwmiu37iaSB-dGd5Xpy-OQ2Fq7D3I','2026-02-17 21:13:40','2026-02-16 03:22:48',NULL,NULL,NULL,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,0),(5,'admin',NULL,'scrypt:32768:8:1$ZvSIgzzLcZ0VId1V$97fb412e77901f3450542acd18dda57e5d476fcd9ea89aeda06771065143baffcc5fbae496e4aeda7cab319050315095c99853a553653f11b4ff5e54841f8a72',NULL,NULL,'2026-02-24 14:25:56',NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,0),(6,'night2','night2@gmail.com','scrypt:32768:8:1$OPFJkbu6u3CvJRkA$85d383dc06241df8387aa6a2674e32eb2d8be0c17b6d64ebfe36aa7716bee573a6a18750d77d49c9b7daae9ce0c8e9a2c84328018f8c45f4101f7446a2be13a2','CXfPaaWVs4fqI9oblL0-annPmeZpNrGjDuwFvXZFmuM','2026-02-25 07:00:29','2026-02-25 13:53:13','ชาย',32,61,170,NULL,NULL,0,NULL,NULL,NULL,NULL,0),(7,'night3','night34@gmail.com','scrypt:32768:8:1$mRzgVDtKD8niDeI3$c373795a5349e545744b08a96538bac6a033a33b55e30926d14d4c59e573eca0d6eb5239d89cf2b616c32d07b4ecebfc7741626735cb034c90229934e37948f6','ohx7mUJwyaURNCV9Lf1phdakp_WKMK0hZ7YvBv9BzPI','2026-03-01 01:39:28','2026-03-01 08:35:47','ชาย',31,49,102,NULL,NULL,0,NULL,NULL,NULL,NULL,0),(8,'night4','night4@gmail.com','scrypt:32768:8:1$DkcoWDuoKHMYAtAK$709e62b3b20bb601c7e49987dd427997a91342c73257c8c2d5048bd5a70e4e8fd3bf25b2d09fc6e6512da487a6b520d5ed0654d8994fdd089364fdac0f78f5ca','oOgzP6ANoKFXMQzfqMOw0TOnjo4_lm3_wK5aENd_Mmg','2026-03-01 01:53:40','2026-03-01 08:45:45','ชาย',32,52,144,NULL,NULL,0,NULL,NULL,NULL,NULL,0);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-03-01 15:59:17
