-- phpMyAdmin SQL Dump
-- version 5.1.0
-- https://www.phpmyadmin.net/
--
-- Hôte : localhost
-- Généré le : ven. 10 juin 2022 à 07:29
-- Version du serveur :  10.4.18-MariaDB
-- Version de PHP : 8.0.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `clickandcollect`
--

DELIMITER $$
--
-- Procédures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_slot` (IN `d` DATE)  NO SQL
BEGIN
INSERT INTO timeslot (`slotDate`, `full`, `expired`) VALUES (@d, '0', '0');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `timeslot_generation` (IN `date_limit` DATE)  NO SQL
BEGIN
  DECLARE done BOOLEAN DEFAULT FALSE;
  DECLARE vname TIME;
  DECLARE vdays VARCHAR(20);
  DECLARE dow CHARACTER;
  DECLARE day DATE DEFAULT CURRENT_DATE;
  DECLARE nd DATETIME;
  DECLARE curTime CURSOR FOR SELECT `name`,`days` FROM slot;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  WHILE DATEDIFF(date_limit,day)>0 do

    OPEN curTime;
      read_loop: LOOP
        FETCH curTime INTO vname, vdays;
        IF done THEN
          LEAVE read_loop;
        END IF;
        SET dow=CONVERT(WEEKDAY(day)+1,CHARACTER);
        IF (LOCATE(dow,vdays) > 0) THEN
            SET nd=STR_TO_DATE(CONCAT(day, ' ', vname), '%Y-%m-%d %H:%i:%s');
            SELECT nd;
            INSERT IGNORE INTO timeslot (`slotDate`) VALUES (nd);
        END IF;
      END LOOP;
    CLOSE curTime;
    SET done=FALSE;
    SET day=DATE_ADD(day, INTERVAL 1 DAY);
  END WHILE;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrderAmount` (IN `id_Order` INT)  BEGIN
	update `order` set amount=(select sum(p.price*o.quantity) from orderdetail o inner JOIN product p on p.id=o.idProduct where o.idOrder=id_Order) where id=id_Order;
    	update `order` set toPay=(select sum(p.price*o.quantity) from orderdetail o inner JOIN product p on p.id=o.idProduct where o.idOrder=id_Order and o.prepared) where id=id_Order;
        update `order` set missingNumber=(select sum(o.quantity) from orderdetail o inner JOIN product p on p.id=o.idProduct where o.idOrder=id_Order and !o.prepared) where id=id_Order;
        update `order` set itemsNumber=(select sum(o.quantity) from orderdetail o inner JOIN product p on p.id=o.idProduct where o.idOrder=id_Order) where id=id_Order;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateTimeSlot` (IN `id_timeslot` INT)  NO SQL
update timeslot set `full`=isTimeslotFull(id_timeslot), `expired`=isTimeslotExpired(id_timeslot) where id=id_timeslot$$

--
-- Fonctions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `getFreeEmployee` (`id_timeslot` INT) RETURNS INT(11) NO SQL
BEGIN
DECLARE res INT;

SET res=(SELECT e.id FROM employee e where e.id not in (select o.idEmployee from `order` o inner join timeslot t on o.idTimeslot=t.id where t.id=id_timeslot and o.idEmployee is not null) limit 1);
RETURN res;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getPackPromo` (`id_pack` INT) RETURNS FLOAT NO SQL
BEGIN
DECLARE old_p float;
DECLARE new_p float;

SET old_p=(SELECT SUM(p.price) FROM `pack` inner join product p on `pack`.idProduct=p.id WHERE idPack=id_pack);
SET new_p=(SELECT price from product where id=id_pack);
return new_p-old_p;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `isTimeslotExpired` (`id_timeslot` INT) RETURNS TINYINT(1) NO SQL
return (select (slotDate>=CURDATE()-0.5) from timeslot WHERE id=id_timeslot)$$

CREATE DEFINER=`root`@`localhost` FUNCTION `isTimeslotFull` (`id_timeslot` INT) RETURNS INT(11) NO SQL
return (SELECT count(*) FROM `order` WHERE idTimeslot=id_timeslot AND idEmployee is NULL)>=(SELECT COUNT(*) FROM employee e where e.id not in (select o.idEmployee from `order` o inner join timeslot t on o.idTimeslot=t.id where t.id=id_timeslot and o.idEmployee is not null))$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `associatedproduct`
--

CREATE TABLE `associatedproduct` (
  `idProduct` int(11) NOT NULL,
  `idAssoProduct` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `associatedproduct`
--

INSERT INTO `associatedproduct` (`idProduct`, `idAssoProduct`) VALUES
(4, 128),
(4, 130),
(11, 130),
(13, 130),
(16, 130),
(32, 128),
(32, 130),
(43, 130),
(73, 130);

-- --------------------------------------------------------

--
-- Structure de la table `basket`
--

CREATE TABLE `basket` (
  `id` int(11) NOT NULL,
  `name` varchar(60) NOT NULL,
  `dateCreation` timestamp NOT NULL DEFAULT current_timestamp(),
  `idUser` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `basket`
--

INSERT INTO `basket` (`id`, `name`, `dateCreation`, `idUser`) VALUES
(1, 'Mis de côté', '2021-03-05 11:37:45', 2),
(2, 'Mis de côté', '2021-03-06 02:23:11', 3),
(18, '_current_', '2021-03-22 18:54:23', 1),
(19, '_default', '2021-04-25 15:36:16', 1),
(20, 'defaultBasket', '2021-04-26 14:31:41', 1),
(22, 'bla', '2021-04-26 17:31:50', 1),
(23, 'Emma', '2021-04-27 00:15:23', 1);

-- --------------------------------------------------------

--
-- Structure de la table `basketdetail`
--

CREATE TABLE `basketdetail` (
  `idBasket` int(11) NOT NULL,
  `idProduct` int(11) NOT NULL,
  `quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `basketdetail`
--

INSERT INTO `basketdetail` (`idBasket`, `idProduct`, `quantity`) VALUES
(2, 6, 1),
(18, 37, 1),
(20, 4, 1),
(20, 37, 1);

-- --------------------------------------------------------

--
-- Structure de la table `employee`
--

CREATE TABLE `employee` (
  `id` int(11) NOT NULL,
  `name` varchar(60) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `employee`
--

INSERT INTO `employee` (`id`, `name`, `email`, `password`) VALUES
(1, 'Mario', 'mario@nintendo.org', '0000'),
(2, 'Luigi', 'luigi@nintendo.org', '0000'),
(3, 'Waluigi', 'Waluigi@nintendo.org', '0000');

-- --------------------------------------------------------

--
-- Structure de la table `order`
--

CREATE TABLE `order` (
  `id` int(11) NOT NULL,
  `dateCreation` timestamp NOT NULL DEFAULT current_timestamp(),
  `idUser` int(11) NOT NULL,
  `idEmployee` int(11) DEFAULT NULL,
  `status` varchar(100) NOT NULL,
  `amount` decimal(6,2) NOT NULL,
  `toPay` decimal(6,2) NOT NULL,
  `itemsNumber` int(11) NOT NULL,
  `missingNumber` int(11) NOT NULL,
  `idTimeslot` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `order`
--

INSERT INTO `order` (`id`, `dateCreation`, `idUser`, `idEmployee`, `status`, `amount`, `toPay`, `itemsNumber`, `missingNumber`, `idTimeslot`) VALUES
(1, '2021-03-03 12:10:31', 1, 1, 'created', '96.00', '2.00', 1, 1, 1),
(3, '2021-03-03 18:44:16', 1, 2, 'created', '147.74', '0.00', 1, 1, 1),
(4, '2021-03-04 10:52:53', 1, 1, 'created', '99.21', '0.00', 1, 1, 2),
(8, '2021-03-04 11:05:50', 1, 2, 'created', '274.70', '0.00', 3, 3, 2),
(9, '2021-03-05 11:43:03', 2, 3, 'created', '118.94', '2.00', 1, 1, 2),
(13, '2021-03-06 13:12:42', 3, 1, 'prepared', '972.85', '0.00', 5, 5, 3),
(15, '2021-03-07 11:56:07', 3, 2, 'created', '1730.20', '0.00', 10, 10, 3),
(19, '2021-04-11 13:18:50', 1, NULL, 'created', '9999.99', '0.00', 185, 185, NULL),
(24, '2021-04-11 13:32:40', 1, NULL, 'created', '6943.40', '0.00', 60, 60, NULL),
(25, '2021-04-25 15:39:31', 1, 1, 'created', '118.50', '0.00', 1, 1, 6101),
(26, '2021-04-26 17:28:59', 1, NULL, 'created', '0.00', '2.00', 0, 0, NULL),
(27, '2021-04-26 17:32:49', 1, NULL, 'created', '194.57', '2.00', 1, 1, NULL),
(28, '2021-04-28 10:01:37', 1, NULL, 'created', '270.00', '0.00', 1, 1, NULL),
(29, '2022-06-09 15:18:42', 1, NULL, 'created', '0.00', '0.00', 1, 0, NULL),
(30, '2022-06-09 15:24:16', 1, NULL, 'created', '147.74', '0.00', 1, 0, NULL),
(31, '2022-06-09 15:25:12', 1, NULL, 'created', '147.74', '0.00', 1, 0, NULL),
(32, '2022-06-09 15:25:38', 1, NULL, 'created', '147.74', '0.00', 1, 0, NULL),
(33, '2022-06-09 15:29:39', 1, NULL, 'created', '147.74', '0.00', 1, 0, NULL),
(34, '2022-06-09 15:30:32', 1, NULL, 'created', '147.74', '0.00', 1, 0, NULL),
(35, '2022-06-09 15:31:07', 1, NULL, 'created', '147.74', '0.00', 1, 0, NULL),
(36, '2022-06-09 15:31:25', 1, NULL, 'created', '147.74', '0.00', 1, 0, NULL),
(37, '2022-06-09 15:31:43', 1, NULL, 'created', '147.74', '0.00', 1, 0, NULL),
(38, '2022-06-09 15:32:29', 1, NULL, 'created', '147.74', '0.00', 1, 0, NULL),
(39, '2022-06-09 15:33:02', 1, NULL, 'created', '147.74', '0.00', 1, 1, NULL),
(40, '2022-06-09 15:34:39', 1, NULL, 'created', '147.74', '0.00', 1, 0, NULL),
(41, '2022-06-09 15:35:04', 1, NULL, 'created', '147.74', '0.00', 1, 1, NULL),
(42, '2022-06-09 15:36:24', 1, NULL, 'created', '147.74', '0.00', 1, 1, NULL),
(43, '2022-06-09 15:36:37', 1, NULL, 'created', '147.74', '0.00', 1, 1, NULL),
(44, '2022-06-09 15:37:06', 1, NULL, 'created', '147.74', '0.00', 1, 0, NULL),
(45, '2022-06-09 15:37:16', 1, NULL, 'created', '147.74', '0.00', 1, 1, NULL),
(46, '2022-06-09 15:48:29', 1, NULL, 'created', '147.74', '0.00', 1, 1, NULL),
(47, '2022-06-09 15:48:36', 1, NULL, 'created', '147.74', '0.00', 1, 1, NULL),
(48, '2022-06-09 15:48:56', 1, NULL, 'created', '147.74', '0.00', 1, 1, NULL),
(49, '2022-06-09 15:53:10', 1, NULL, 'created', '147.74', '0.00', 1, 1, NULL);

--
-- Déclencheurs `order`
--
DELIMITER $$
CREATE TRIGGER `after_insert_order` AFTER INSERT ON `order` FOR EACH ROW if (NEW.idTimeslot is NOT NULL) THEN
    call updateTimeSlot(NEW.idTimeslot);
END IF
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_insert_order` BEFORE INSERT ON `order` FOR EACH ROW BEGIN
IF (NEW.idEmployee IS NULL) THEN
    IF(NEW.idTimeslot IS NOT NULL) THEN
        SET NEW.idEmployee=getFreeEmployee(NEW.idTimeslot);
    END IF;
END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `delete_order` AFTER DELETE ON `order` FOR EACH ROW if (OLD.idTimeslot is NOT NULL) THEN
    call updateTimeSlot(OLD.idTimeslot);
end if
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_order` AFTER UPDATE ON `order` FOR EACH ROW if (NEW.idTimeslot is NOT NULL) THEN
    call updateTimeSlot(NEW.idTimeslot);
ELSEIF(OLD.idTimeslot is NOT NULL) THEN
    call updateTimeSlot(OLD.idTimeslot);
end if
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `orderdetail`
--

CREATE TABLE `orderdetail` (
  `idOrder` int(11) NOT NULL,
  `idProduct` int(11) NOT NULL,
  `quantity` decimal(6,2) NOT NULL,
  `prepared` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `orderdetail`
--

INSERT INTO `orderdetail` (`idOrder`, `idProduct`, `quantity`, `prepared`) VALUES
(3, 6, '1.00', 0),
(4, 44, '1.00', 0),
(8, 27, '1.00', 0),
(8, 76, '2.00', 0),
(15, 13, '10.00', 0),
(19, 5, '5.00', 0),
(19, 6, '5.00', 0),
(19, 8, '5.00', 0),
(19, 11, '5.00', 0),
(19, 12, '5.00', 0),
(19, 13, '5.00', 0),
(19, 14, '5.00', 0),
(19, 16, '5.00', 0),
(19, 18, '5.00', 0),
(19, 21, '5.00', 0),
(19, 24, '5.00', 0),
(19, 25, '5.00', 0),
(19, 26, '5.00', 0),
(19, 34, '5.00', 0),
(19, 40, '5.00', 0),
(19, 41, '5.00', 0),
(19, 43, '5.00', 0),
(19, 45, '5.00', 0),
(19, 46, '5.00', 0),
(19, 49, '5.00', 0),
(19, 54, '5.00', 0),
(19, 55, '5.00', 0),
(19, 56, '5.00', 0),
(19, 57, '5.00', 0),
(19, 59, '5.00', 0),
(19, 67, '5.00', 0),
(19, 68, '5.00', 0),
(19, 70, '5.00', 0),
(19, 71, '5.00', 0),
(19, 73, '5.00', 0),
(19, 74, '5.00', 0),
(19, 76, '5.00', 0),
(19, 78, '5.00', 0),
(19, 81, '5.00', 0),
(19, 84, '5.00', 0),
(19, 103, '5.00', 0),
(19, 136, '5.00', 0),
(24, 4, '5.00', 0),
(24, 10, '5.00', 0),
(24, 32, '5.00', 0),
(24, 47, '5.00', 0),
(24, 58, '5.00', 0),
(24, 62, '5.00', 0),
(24, 66, '5.00', 0),
(24, 86, '5.00', 0),
(24, 87, '5.00', 0),
(24, 92, '5.00', 0),
(24, 96, '5.00', 0),
(24, 128, '5.00', 0),
(25, 15, '1.00', 0),
(28, 129, '1.00', 0),
(39, 6, '1.00', 0),
(41, 6, '1.00', 0),
(42, 6, '1.00', 0),
(43, 6, '1.00', 0),
(45, 6, '1.00', 0),
(46, 6, '1.00', 0),
(47, 6, '1.00', 0),
(48, 6, '1.00', 0),
(49, 6, '1.00', 0);

--
-- Déclencheurs `orderdetail`
--
DELIMITER $$
CREATE TRIGGER `delete_order_detail` AFTER DELETE ON `orderdetail` FOR EACH ROW CALL updateOrderAmount (
        OLD.idOrder
    )
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `insert_order_detail` AFTER INSERT ON `orderdetail` FOR EACH ROW CALL updateOrderAmount (
        NEW.idOrder
    )
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_order_detail` AFTER UPDATE ON `orderdetail` FOR EACH ROW CALL updateOrderAmount (
        NEW.idOrder
    )
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `pack`
--

CREATE TABLE `pack` (
  `idProduct` int(11) NOT NULL,
  `idPack` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `pack`
--

INSERT INTO `pack` (`idProduct`, `idPack`) VALUES
(4, 128),
(4, 130),
(11, 130),
(13, 130),
(16, 130),
(32, 128),
(32, 130),
(43, 130),
(73, 130);

--
-- Déclencheurs `pack`
--
DELIMITER $$
CREATE TRIGGER `delete_associated` AFTER DELETE ON `pack` FOR EACH ROW BEGIN
DELETE FROM `associatedproduct` WHERE idProduct=OLD.idProduct AND idAssoproduct=OLD.idPack;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `insert_associated` AFTER INSERT ON `pack` FOR EACH ROW BEGIN
DECLARE promo float;
INSERT INTO `associatedproduct`(idProduct,idAssoproduct) VALUES(NEW.idProduct,NEW.idPack);
SET promo = getPackPromo(NEW.idPack);
UPDATE product SET promotion= promo where id=NEW.idPack;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `product`
--

CREATE TABLE `product` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `comments` text DEFAULT NULL,
  `stock` int(11) NOT NULL,
  `image` text DEFAULT NULL,
  `price` decimal(6,2) NOT NULL,
  `promotion` decimal(6,2) NOT NULL,
  `idSection` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `product`
--

INSERT INTO `product` (`id`, `name`, `comments`, `stock`, `image`, `price`, `promotion`, `idSection`) VALUES
(4, '2003 Harley-Davidson Eagle Drag Bike', 'Model features, official Harley Davidson logos and insignias, detachable rear wheelie bar, heavy diecast metal with resin parts, authentic multi-color tampo-printed graphics, separate engine drive belts, free-turning front fork, rotating tires and rear racing slick, certificate of authenticity, detailed engine, display stand\r\n, precision diecast replica, baked enamel finish, 1:10 scale model, removable fender, seat and tank cover piece for displaying the superior detail of the v-twin engine', 5582, 'S10_4698', '193.66', '0.00', 2),
(5, '1972 Alfa Romeo GTA', 'Features include: Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 3252, 'S10_4757', '136.00', '0.00', 1),
(6, '1962 LanciaA Delta 16V', 'Features include: Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 6770, 'S10_4962', '147.74', '0.00', 1),
(8, '2001 Ferrari Enzo', 'Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 3619, 'S12_1108', '207.80', '0.00', 1),
(10, '2002 Suzuki XREO', 'Official logos and insignias, saddle bags located on side of motorcycle, detailed engine, working steering, working suspension, two leather seats, luggage rack, dual exhaust pipes, small saddle bag located on handle bars, two-tone paint with chrome accents, superior die-cast detail , rotating wheels , working kick stand, diecast metal with plastic parts and baked enamel finish.', 9997, 'S12_2823', '150.62', '0.00', 2),
(11, '1969 Corvair Monza', '1:18 scale die-cast about 10\" long doors open, hood opens, trunk opens and wheels roll', 6906, 'S12_3148', '151.08', '0.00', 1),
(12, '1968 Dodge Charger', '1:12 scale model of a 1968 Dodge Charger. Hood, doors and trunk all open to reveal highly detailed interior features. Steering wheel actually turns the front wheels. Color black', 9123, 'S12_3380', '117.44', '0.00', 1),
(13, '1969 Ford Falcon', 'Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 1049, 'S12_3891', '173.02', '0.00', 1),
(14, '1970 Plymouth Hemi Cuda', 'Very detailed 1970 Plymouth Cuda model in 1:12 scale. The Cuda is generally accepted as one of the fastest original muscle cars from the 1970s. This model is a reproduction of one of the orginal 652 cars built in 1970. Red color.', 5663, 'S12_3990', '79.80', '0.00', 1),
(15, '1957 Chevy Pickup', '1:12 scale die-cast about 20\" long Hood opens, Rubber wheels', 6125, 'S12_4473', '118.50', '0.00', 6),
(16, '1969 Dodge Charger', 'Detailed model of the 1969 Dodge Charger. This model includes finely detailed interior and exterior features. Painted in red and white.', 7323, 'S12_4675', '115.16', '0.00', 1),
(17, '1940 Ford Pickup Truck', 'This model features soft rubber tires, working steering, rubber mud guards, authentic Ford logos, detailed undercarriage, opening doors and hood,  removable split rear gate, full size spare mounted in bed, detailed interior with opening glove box', 2613, 'S18_1097', '116.67', '0.00', 6),
(18, '1993 Mazda RX-7', 'This model features, opening hood, opening doors, detailed engine, rear spoiler, opening trunk, working steering, tinted windows, baked enamel finish. Color red.', 3975, 'S18_1129', '141.54', '0.00', 1),
(19, '1937 Lincoln Berline', 'Features opening engine cover, doors, trunk, and fuel filler cap. Color black', 8693, 'S18_1342', '102.74', '0.00', 7),
(20, '1936 Mercedes-Benz 500K Special Roadster', 'This 1:18 scale replica is constructed of heavy die-cast metal and has all the features of the original: working doors and rumble seat, independent spring suspension, detailed interior, working steering system, and a bifold hood that reveals an engine so accurate that it even includes the wiring. All this is topped off with a baked enamel finish. Color white.', 8635, 'S18_1367', '53.91', '0.00', 7),
(21, '1965 Aston Martin DB5', 'Die-cast model of the silver 1965 Aston Martin DB5 in silver. This model includes full wire wheels and doors that open with fully detailed passenger compartment. In 1:18 scale, this model measures approximately 10 inches/20 cm long.', 9042, 'S18_1589', '124.44', '0.00', 1),
(23, '1917 Grand Touring Sedan', 'This 1:18 scale replica of the 1917 Grand Touring car has all the features you would expect from museum quality reproductions: all four doors and bi-fold hood opening, detailed engine and instrument panel, chrome-look trim, and tufted upholstery, all topped off with a factory baked-enamel finish.', 2724, 'S18_1749', '170.00', '0.00', 7),
(24, '1948 Porsche 356-A Roadster', 'This precision die-cast replica features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 8826, 'S18_1889', '77.00', '0.00', 1),
(25, '1995 Honda Civic', 'This model features, opening hood, opening doors, detailed engine, rear spoiler, opening trunk, working steering, tinted windows, baked enamel finish. Color yellow.', 9772, 'S18_1984', '142.25', '0.00', 1),
(26, '1998 Chrysler Plymouth Prowler', 'Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 4724, 'S18_2238', '163.73', '0.00', 1),
(27, '1911 Ford Town Car', 'Features opening hood, opening doors, opening trunk, wide white wall tires, front door arm rests, working steering system.', 540, 'S18_2248', '60.54', '0.00', 7),
(28, '1964 Mercedes Tour Bus', 'Exact replica. 100+ parts. working steering system, original logos', 8258, 'S18_2319', '122.73', '0.00', 6),
(29, '1932 Model A Ford J-Coupe', 'This model features grille-mounted chrome horn, lift-up louvered hood, fold-down rumble seat, working steering system, chrome-covered spare, opening doors, detailed and wired engine', 9354, 'S18_2325', '127.13', '0.00', 7),
(30, '1926 Ford Fire Engine', 'Gleaming red handsome appearance. Everything is here the fire hoses, ladder, axes, bells, lanterns, ready to fight any inferno.', 2018, 'S18_2432', '60.77', '0.00', 6),
(32, '1936 Harley Davidson El Knucklehead', 'Intricately detailed with chrome accents and trim, official die-struck logos and baked enamel finish.', 4357, 'S18_2625', '60.57', '0.00', 2),
(33, '1928 Mercedes-Benz SSK', 'This 1:18 replica features grille-mounted chrome horn, lift-up louvered hood, fold-down rumble seat, working steering system, chrome-covered spare, opening doors, detailed and wired engine. Color black.', 548, 'S18_2795', '168.75', '0.00', 7),
(34, '1999 Indy 500 Monte Carlo SS', 'Features include opening and closing doors. Color: Red', 8164, 'S18_2870', '132.00', '0.00', 1),
(35, '1913 Ford Model T Speedster', 'This 250 part reproduction includes moving handbrakes, clutch, throttle and foot pedals, squeezable horn, detailed wired engine, removable water, gas, and oil cans, pivoting monocle windshield, all topped with a baked enamel red finish. Each replica comes with an Owners Title and Certificate of Authenticity. Color red.', 4189, 'S18_2949', '101.31', '0.00', 7),
(36, '1934 Ford V8 Coupe', 'Chrome Trim, Chrome Grille, Opening Hood, Opening Doors, Opening Trunk, Detailed Engine, Working Steering System', 5649, 'S18_2957', '62.46', '0.00', 7),
(37, '1999 Yamaha Speed Boat', 'Exact replica. Wood and Metal. Many extras including rigging, long boats, pilot house, anchors, etc. Comes with three masts, all square-rigged.', 4259, 'S18_3029', '86.02', '0.00', 4),
(38, '18th Century Vintage Horse Carriage', 'Hand crafted diecast-like metal horse carriage is re-created in about 1:18 scale of antique horse carriage. This antique style metal Stagecoach is all hand-assembled with many different parts.\r\n\r\nThis collectible metal horse carriage is painted in classic Red, and features turning steering wheel and is entirely hand-finished.', 5992, 'S18_3136', '104.72', '0.00', 7),
(39, '1903 Ford Model A', 'Features opening trunk,  working steering system', 3913, 'S18_3140', '136.59', '0.00', 7),
(40, '1992 Ferrari 360 Spider red', 'his replica features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 8347, 'S18_3232', '169.34', '0.00', 1),
(41, '1985 Toyota Supra', 'This model features soft rubber tires, working steering, rubber mud guards, authentic Ford logos, detailed undercarriage, opening doors and hood, removable split rear gate, full size spare mounted in bed, detailed interior with opening glove box', 7733, 'S18_3233', '107.57', '0.00', 1),
(42, 'Collectable Wooden Train', 'Hand crafted wooden toy train set is in about 1:18 scale, 25 inches in total length including 2 additional carts, of actual vintage train. This antique style wooden toy train model set is all hand-assembled with 100% wood.', 6450, 'S18_3259', '100.84', '0.00', 5),
(43, '1969 Dodge Super Bee', 'This replica features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 1917, 'S18_3278', '80.41', '0.00', 1),
(44, '1917 Maxwell Touring Car', 'Features Gold Trim, Full Size Spare Tire, Chrome Trim, Chrome Grille, Opening Hood, Opening Doors, Opening Trunk, Detailed Engine, Working Steering System', 7913, 'S18_3320', '99.21', '0.00', 7),
(45, '1976 Ford Gran Torino', 'Highly detailed 1976 Ford Gran Torino \"Starsky and Hutch\" diecast model. Very well constructed and painted in red and white patterns.', 9127, 'S18_3482', '146.99', '0.00', 1),
(46, '1948 Porsche Type 356 Roadster', 'This model features working front and rear suspension on accurately replicated and actuating shock absorbers as well as opening engine cover, rear stabilizer flap,  and 4 opening doors.', 8990, 'S18_3685', '141.28', '0.00', 1),
(47, '1957 Vespa GS150', 'Features rotating wheels , working kick stand. Comes with stand.', 7689, 'S18_3782', '62.17', '0.00', 2),
(48, '1941 Chevrolet Special Deluxe Cabriolet', 'Features opening hood, opening doors, opening trunk, wide white wall tires, front door arm rests, working steering system, leather upholstery. Color black.', 2378, 'S18_3856', '105.87', '0.00', 7),
(49, '1970 Triumph Spitfire', 'Features include opening and closing doors. Color: White.', 5545, 'S18_4027', '143.62', '0.00', 1),
(50, '1932 Alfa Romeo 8C2300 Spider Sport', 'This 1:18 scale precision die cast replica features the 6 front headlights of the original, plus a detailed version of the 142 horsepower straight 8 engine, dual spares and their famous comprehensive dashboard. Color black.', 6553, 'S18_4409', '92.03', '0.00', 7),
(51, '1904 Buick Runabout', 'Features opening trunk,  working steering system', 8290, 'S18_4522', '87.77', '0.00', 7),
(52, '1940s Ford truck', 'This 1940s Ford Pick-Up truck is re-created in 1:18 scale of original 1940s Ford truck. This antique style metal 1940s Ford Flatbed truck is all hand-assembled. This collectible 1940\'s Pick-Up truck is painted in classic dark green color, and features rotating wheels.', 3128, 'S18_4600', '121.08', '0.00', 6),
(53, '1939 Cadillac Limousine', 'Features completely detailed interior including Velvet flocked drapes,deluxe wood grain floor, and a wood grain casket with seperate chrome handles', 6645, 'S18_4668', '50.31', '0.00', 7),
(54, '1957 Corvette Convertible', '1957 die cast Corvette Convertible in Roman Red with white sides and whitewall tires. 1:18 scale quality die-cast with detailed engine and underbvody. Now you can own The Classic Corvette.', 1249, 'S18_4721', '148.80', '0.00', 1),
(55, '1957 Ford Thunderbird', 'This 1:18 scale precision die-cast replica, with its optional porthole hardtop and factory baked-enamel Thunderbird Bronze finish, is a 100% accurate rendition of this American classic.', 3209, 'S18_4933', '71.27', '0.00', 1),
(56, '1970 Chevy Chevelle SS 454', 'This model features rotating wheels, working streering system and opening doors. All parts are particularly delicate due to their precise scale and require special care and attention. It should not be picked up by the doors, roof, hood or trunk.', 1005, 'S24_1046', '73.49', '0.00', 1),
(57, '1970 Dodge Coronet', '1:24 scale die-cast about 18\" long doors open, hood opens and rubber wheels', 4074, 'S24_1444', '57.80', '0.00', 1),
(58, '1997 BMW R 1100 S', 'Detailed scale replica with working suspension and constructed from over 70 parts', 7003, 'S24_1578', '112.70', '0.00', 2),
(59, '1966 Shelby Cobra 427 S/C', 'This diecast model of the 1966 Shelby Cobra 427 S/C includes many authentic details and operating parts. The 1:24 scale model of this iconic lighweight sports car from the 1960s comes in silver and it\'s own display case.', 8197, 'S24_1628', '50.31', '0.00', 1),
(60, '1928 British Royal Navy Airplane', 'Official logos and insignias', 3627, 'S24_1785', '109.42', '0.00', 3),
(61, '1939 Chevrolet Deluxe Coupe', 'This 1:24 scale die-cast replica of the 1939 Chevrolet Deluxe Coupe has the same classy look as the original. Features opening trunk, hood and doors and a showroom quality baked enamel finish.', 7332, 'S24_1937', '33.19', '0.00', 7),
(62, '1960 BSA Gold Star DBD34', 'Detailed scale replica with working suspension and constructed from over 70 parts', 15, 'S24_2000', '76.17', '0.00', 2),
(64, '1938 Cadillac V-16 Presidential Limousine', 'This 1:24 scale precision die cast replica of the 1938 Cadillac V-16 Presidential Limousine has all the details of the original, from the flags on the front to an opening back seat compartment complete with telephone and rifle. Features factory baked-enamel black finish, hood goddess ornament, working jump seats.', 2847, 'S24_2022', '44.80', '0.00', 7),
(65, '1962 Volkswagen Microbus', 'This 1:18 scale die cast replica of the 1962 Microbus is loaded with features: A working steering system, opening front doors and tailgate, and famous two-tone factory baked enamel finish, are all topped of by the sliding, real fabric, sunroof.', 2327, 'S24_2300', '127.79', '0.00', 6),
(66, '1982 Ducati 900 Monster', 'Features two-tone paint with chrome accents, superior die-cast detail , rotating wheels , working kick stand', 6840, 'S24_2360', '69.26', '0.00', 2),
(67, '1949 Jaguar XK 120', 'Precision-engineered from original Jaguar specification in perfect scale ratio. Features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 2350, 'S24_2766', '90.87', '0.00', 1),
(68, '1958 Chevy Corvette Limited Edition', 'The operating parts of this 1958 Chevy Corvette Limited Edition are particularly delicate due to their precise scale and require special care and attention. Features rotating wheels, working streering, opening doors and trunk. Color dark green.', 2542, 'S24_2840', '35.36', '0.00', 1),
(69, '1900s Vintage Bi-Plane', 'Hand crafted diecast-like metal bi-plane is re-created in about 1:24 scale of antique pioneer airplane. All hand-assembled with many different parts. Hand-painted in classic yellow and features correct markings of original airplane.', 5942, 'S24_2841', '68.51', '0.00', 3),
(70, '1952 Citroen-15CV', 'Precision crafted hand-assembled 1:18 scale reproduction of the 1952 15CV, with its independent spring suspension, working steering system, opening doors and hood, detailed engine and instrument panel, all topped of with a factory fresh baked enamel finish.', 1452, 'S24_2887', '117.44', '0.00', 1),
(71, '1982 Lamborghini Diablo', 'This replica features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 7723, 'S24_2972', '37.76', '0.00', 1),
(72, '1912 Ford Model T Delivery Wagon', 'This model features chrome trim and grille, opening hood, opening doors, opening trunk, detailed engine, working steering system. Color white.', 9173, 'S24_3151', '88.51', '0.00', 7),
(73, '1969 Chevrolet Camaro Z28', '1969 Z/28 Chevy Camaro 1:24 scale replica. The operating parts of this limited edition 1:24 scale diecast model car 1969 Chevy Camaro Z28- hood, trunk, wheels, streering, suspension and doors- are particularly delicate due to their precise scale and require special care and attention.', 4695, 'S24_3191', '85.61', '0.00', 1),
(74, '1971 Alpine Renault 1600s', 'This 1971 Alpine Renault 1600s replica Features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 7995, 'S24_3371', '61.23', '0.00', 1),
(75, '1937 Horch 930V Limousine', 'Features opening hood, opening doors, opening trunk, wide white wall tires, front door arm rests, working steering system', 2902, 'S24_3420', '65.75', '0.00', 7),
(76, '2002 Chevy Corvette', 'The operating parts of this limited edition Diecast 2002 Chevy Corvette 50th Anniversary Pace car Limited Edition are particularly delicate due to their precise scale and require special care and attention. Features rotating wheels, poseable streering, opening doors and trunk.', 9446, 'S24_3432', '107.08', '0.00', 1),
(77, '1940 Ford Delivery Sedan', 'Chrome Trim, Chrome Grille, Opening Hood, Opening Doors, Opening Trunk, Detailed Engine, Working Steering System. Color black.', 6621, 'S24_3816', '83.86', '0.00', 7),
(78, '1956 Porsche 356A Coupe', 'Features include: Turnable front wheels; steering function; detailed interior; detailed engine; opening hood; opening trunk; opening doors; and detailed chassis.', 6600, 'S24_3856', '140.43', '0.00', 1),
(79, 'Corsair F4U ( Bird Cage)', 'Has retractable wheels and comes with a stand. Official logos and insignias.', 6812, 'S24_3949', '68.24', '0.00', 3),
(80, '1936 Mercedes Benz 500k Roadster', 'This model features grille-mounted chrome horn, lift-up louvered hood, fold-down rumble seat, working steering system and rubber wheels. Color black.', 2081, 'S24_3969', '41.03', '0.00', 7),
(81, '1992 Porsche Cayenne Turbo Silver', 'This replica features opening doors, superb detail and craftsmanship, working steering system, opening forward compartment, opening rear trunk with removable spare, 4 wheel independent spring suspension as well as factory baked enamel finish.', 6582, 'S24_4048', '118.28', '0.00', 1),
(82, '1936 Chrysler Airflow', 'Features opening trunk,  working steering system. Color dark green.', 4710, 'S24_4258', '97.39', '0.00', 7),
(83, '1900s Vintage Tri-Plane', 'Hand crafted diecast-like metal Triplane is Re-created in about 1:24 scale of antique pioneer airplane. This antique style metal triplane is all hand-assembled with many different parts.', 2756, 'S24_4278', '72.45', '0.00', 3),
(84, '1961 Chevrolet Impala', 'This 1:18 scale precision die-cast reproduction of the 1961 Chevrolet Impala has all the features-doors, hood and trunk that open; detailed 409 cubic-inch engine; chrome dashboard and stick shift, two-tone interior; working steering system; all topped of with a factory baked-enamel finish.', 7869, 'S24_4620', '80.84', '0.00', 1),
(85, '1980’s GM Manhattan Express', 'This 1980’s era new look Manhattan express is still active, running from the Bronx to mid-town Manhattan. Has 35 opeining windows and working lights. Needs a battery.', 5099, 'S32_1268', '96.31', '0.00', 6),
(86, '1997 BMW F650 ST', 'Features official die-struck logos and baked enamel finish. Comes with stand.', 178, 'S32_1374', '99.89', '0.00', 2),
(87, '1982 Ducati 996 R', 'Features rotating wheels , working kick stand. Comes with stand.', 9241, 'S32_2206', '40.23', '0.00', 2),
(88, '1954 Greyhound Scenicruiser', 'Model features bi-level seating, 50 windows, skylights & glare resistant glass, working steering system, original logos', 2874, 'S32_2509', '54.11', '0.00', 6),
(89, '1950\'s Chicago Surface Lines Streetcar', 'This streetcar is a joy to see. It has 80 separate windows, electric wire guides, detailed interiors with seats, poles and drivers controls, rolling and turning wheel assemblies, plus authentic factory baked-enamel finishes (Green Hornet for Chicago and Cream and Crimson for Boston).', 8601, 'S32_3207', '62.14', '0.00', 5),
(90, '1996 Peterbilt 379 Stake Bed with Outrigger', 'This model features, opening doors, detailed engine, working steering, tinted windows, detailed interior, die-struck logos, removable stakes operating outriggers, detachable second trailer, functioning 360-degree self loader, precision molded resin trailer and trim, baked enamel finish on cab', 814, 'S32_3522', '64.64', '0.00', 6),
(91, '1928 Ford Phaeton Deluxe', 'This model features grille-mounted chrome horn, lift-up louvered hood, fold-down rumble seat, working steering system', 136, 'S32_4289', '68.79', '0.00', 7),
(92, '1974 Ducati 350 Mk3 Desmo', 'This model features two-tone paint with chrome accents, superior die-cast detail , rotating wheels , working kick stand', 3341, 'S32_4485', '102.05', '0.00', 2),
(93, '1930 Buick Marquette Phaeton', 'Features opening trunk,  working steering system', 7062, 'S50_1341', '43.64', '0.00', 7),
(94, 'Diamond T620 Semi-Skirted Tanker', 'This limited edition model is licensed and perfectly scaled for Lionel Trains. The Diamond T620 has been produced in solid precision diecast and painted with a fire baked enamel finish. It comes with a removable tanker and is a perfect model to add authenticity to your static train or car layout or to just have on display.', 1016, 'S50_1392', '115.75', '0.00', 6),
(95, '1962 City of Detroit Streetcar', 'This streetcar is a joy to see. It has 99 separate windows, electric wire guides, detailed interiors with seats, poles and drivers controls, rolling and turning wheel assemblies, plus authentic factory baked-enamel finishes (Green Hornet for Chicago and Cream and Crimson for Boston).', 1645, 'S50_1514', '58.58', '0.00', 5),
(96, '2002 Yamaha YZR M1', 'Features rotating wheels , working kick stand. Comes with stand.', 600, 'S50_4713', '81.36', '0.00', 2),
(97, 'The Schooner Bluenose', 'All wood with canvas sails. Measures 31 1/2 inches in Length, 22 inches High and 4 3/4 inches Wide. Many extras.\r\nThe schooner Bluenose was built in Nova Scotia in 1921 to fish the rough waters off the coast of Newfoundland. Because of the Bluenose racing prowess she became the pride of all Canadians. Still featured on stamps and the Canadian dime, the Bluenose was lost off Haiti in 1946.', 1897, 'S700_1138', '66.67', '0.00', 4),
(98, 'American Airlines: B767-300', 'Exact replia with official logos and insignias and retractable wheels', 5841, 'S700_1691', '91.34', '0.00', 3),
(99, 'The Mayflower', 'Measures 31 1/2 inches Long x 25 1/2 inches High x 10 5/8 inches Wide\r\nAll wood with canvas sail. Extras include long boats, rigging, ladders, railing, anchors, side cannons, hand painted, etc.', 737, 'S700_1938', '86.61', '0.00', 4),
(100, 'HMS Bounty', 'Measures 30 inches Long x 27 1/2 inches High x 4 3/4 inches Wide. \r\nMany extras including rigging, long boats, pilot house, anchors, etc. Comes with three masts, all square-rigged.', 3501, 'S700_2047', '90.52', '0.00', 4),
(101, 'America West Airlines B757-200', 'Official logos and insignias. Working steering system. Rotating jet engines', 9653, 'S700_2466', '99.72', '0.00', 3),
(102, 'The USS Constitution Ship', 'All wood with canvas sails. Measures 31 1/2\" Length x 22 3/8\" High x 8 1/4\" Width. Extras include 4 boats on deck, sea sprite on bow, anchors, copper railing, pilot houses, etc.', 7083, 'S700_2610', '72.28', '0.00', 4),
(103, '1982 Camaro Z28', 'Features include opening and closing doors. Color: White. \r\nMeasures approximately 9 1/2\" Long.', 6934, 'S700_2824', '101.15', '0.00', 1),
(104, 'ATA: B757-300', 'Exact replia with official logos and insignias and retractable wheels', 7106, 'S700_2834', '118.65', '0.00', 3),
(105, 'F/A 18 Hornet 1/72', '10\" Wingspan with retractable landing gears.Comes with pilot', 551, 'S700_3167', '80.00', '0.00', 3),
(106, 'The Titanic', 'Completed model measures 19 1/2 inches long, 9 inches high, 3inches wide and is in barn red/black. All wood and metal.', 1956, 'S700_3505', '100.17', '0.00', 4),
(107, 'The Queen Mary', 'Exact replica. Wood and Metal. Many extras including rigging, long boats, pilot house, anchors, etc. Comes with three masts, all square-rigged.', 5088, 'S700_3962', '99.31', '0.00', 4),
(108, 'American Airlines: MD-11S', 'Polished finish. Exact replia with official logos and insignias and retractable wheels', 8820, 'S700_4002', '74.03', '0.00', 3),
(109, 'Boeing X-32A JSF', '10\" Wingspan with retractable landing gears.Comes with pilot', 4857, 'S72_1253', '49.66', '0.00', 3),
(110, 'Pont Yacht', 'Measures 38 inches Long x 33 3/4 inches High. Includes a stand.\r\nMany extras including rigging, long boats, pilot house, anchors, etc. Comes with 2 masts, all square-rigged', 414, 'S72_3212', '54.60', '0.00', 4),
(128, 'Harley pack', '', 0, '', '340.00', '-9.93', 2),
(129, 'Mustangs', '', 0, '', '270.00', '-9.05', 7),
(130, '1969', '', 0, '', '660.00', '-823.02', 6),
(136, 'test pack', NULL, 0, NULL, '400.00', '304.00', 1),
(141, 'Test', NULL, 0, NULL, '133.00', '0.00', 7),
(142, 'PC portable', NULL, 0, NULL, '799.00', '0.00', 27),
(143, 'Ecran', NULL, 0, NULL, '22.00', '0.00', 27),
(145, 'Autre', NULL, 0, NULL, '25.00', '0.00', 27),
(147, 'Prod Romero', NULL, 0, NULL, '22.00', '0.00', 41);

--
-- Déclencheurs `product`
--
DELIMITER $$
CREATE TRIGGER `update_product_price` BEFORE UPDATE ON `product` FOR EACH ROW BEGIN
if (OLD.price<>NEW.price) THEN
    SET NEW.promotion = getPackPromo(NEW.id);
END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `section`
--

CREATE TABLE `section` (
  `id` int(11) NOT NULL,
  `name` varchar(60) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `section`
--

INSERT INTO `section` (`id`, `name`, `description`) VALUES
(1, 'Classic cars', 'Attention car enthusiasts: Make your wildest car ownership dreams come true. Whether you are looking for classic muscle cars, dream sports cars or movie-inspired miniatures, you will find great choices in this category. These replicas feature superb attention to detail and craftsmanship and offer features such as working steering system, opening forward compartment, opening rear trunk with removable spare wheel, 4-wheel independent spring suspension, and so on. The models range in size from 1:10 to 1:24 scale and include numerous limited edition and several out-of-production vehicles. All models include a certificate of authenticity from their manufacturers and come fully assembled and ready for display in the home or office.'),
(2, 'Motorcycles', 'Our motorcycles are state of the art replicas of classic as well as contemporary motorcycle legends such as Harley Davidson, Ducati and Vespa. Models contain stunning details such as official logos, rotating wheels, working kickstand, front suspension, gear-shift lever, footbrake lever, and drive chain. Materials used include diecast and plastic. The models range in size from 1:10 to 1:50 scale and include numerous limited edition and several out-of-production vehicles. All models come fully assembled and ready for display in the home or office. Most include a certificate of authenticity.'),
(3, 'Planes', 'Unique, diecast airplane and helicopter replicas suitable for collections, as well as home, office or classroom decorations. Models contain stunning details such as official logos and insignias, rotating jet engines and propellers, retractable wheels, and so on. Most come fully assembled and with a certificate of authenticity from their manufacturers.'),
(4, 'Ships', 'The perfect holiday or anniversary gift for executives, clients, friends, and family. These handcrafted model ships are unique, stunning works of art that will be treasured for generations! They come fully assembled and ready for display in the home or office. We guarantee the highest quality, and best value.'),
(5, 'Trains', 'Model trains are a rewarding hobby for enthusiasts of all ages. Whether you\'re looking for collectible wooden trains, electric streetcars or locomotives, you\'ll find a number of great choices for any budget within this category. The interactive aspect of trains makes toy trains perfect for young children. The wooden train sets are ideal for children under the age of 5.'),
(6, 'Trucks and Buses', 'The Truck and Bus models are realistic replicas of buses and specialized trucks produced from the early 1920s to present. The models range in size from 1:12 to 1:50 scale and include numerous limited edition and several out-of-production vehicles. Materials used include tin, diecast and plastic. All models include a certificate of authenticity from their manufacturers and are a perfect ornament for the home and office.'),
(7, 'Vintage Cars', 'Our Vintage Car models realistically portray automobiles produced from the early 1900s through the 1940s. Materials used include Bakelite, diecast, plastic and wood. Most of the replicas are in the 1:18 and 1:24 scale sizes, which provide the optimum in detail and accuracy. Prices range from $30.00 up to $180.00 for some special limited edition replicas. All models include a certificate of authenticity from their manufacturers and come fully assembled and ready for display in the home or office.'),
(27, 'MySection', 'C\'est ma section'),
(40, 'Jade Christien', NULL),
(41, 'Julie Martineau', NULL),
(47, 'Rian', NULL),
(48, 'Romero', NULL);

-- --------------------------------------------------------

--
-- Structure de la table `slot`
--

CREATE TABLE `slot` (
  `id` int(11) NOT NULL,
  `name` time NOT NULL,
  `days` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `slot`
--

INSERT INTO `slot` (`id`, `name`, `days`) VALUES
(1, '09:00:00', '1,2,3,4,5'),
(2, '09:15:00', '1,2,3,4,5'),
(3, '09:30:00', '1,2,3,4,5'),
(4, '09:45:00', '1,2,3,4,5'),
(5, '10:00:00', '1,2,3,4,5'),
(6, '10:15:00', '1,2,3,4,5'),
(7, '10:30:00', '1,2,3,4,5'),
(8, '10:45:00', '1,2,3,4,5'),
(9, '11:00:00', '1,2,3,4,5'),
(10, '11:15:00', '1,2,3,4,5'),
(11, '11:30:00', '1,2,3,4,5'),
(12, '11:45:00', '1,2,3,4,5'),
(13, '12:00:00', '1,2,3,4,5'),
(14, '14:00:00', '1,2,3,4,5'),
(15, '14:15:00', '1,2,3,4,5'),
(16, '14:30:00', '1,2,3,4,5'),
(17, '14:45:00', '1,2,3,4,5'),
(18, '15:00:00', '1,2,3,4,5'),
(19, '15:15:00', '1,2,3,4,5'),
(20, '15:30:00', '1,2,3,4,5'),
(21, '15:45:00', '1,2,3,4,5'),
(22, '16:00:00', '1,2,3,4,5'),
(23, '16:15:00', '1,2,3,4,5'),
(24, '16:30:00', '1,2,3,4,5'),
(25, '16:45:00', '1,2,3,4,5'),
(26, '17:00:00', '1,2,3,4,5'),
(27, '17:15:00', '1,2,3,4,5'),
(28, '17:30:00', '1,2,3,4,5'),
(29, '17:45:00', '1,2,3,4,5');

-- --------------------------------------------------------

--
-- Structure de la table `timeslot`
--

CREATE TABLE `timeslot` (
  `id` int(11) NOT NULL,
  `slotDate` datetime NOT NULL,
  `full` tinyint(1) NOT NULL DEFAULT 0,
  `expired` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `timeslot`
--

INSERT INTO `timeslot` (`id`, `slotDate`, `full`, `expired`) VALUES
(1, '2021-03-03 12:00:00', 0, 0),
(2, '2021-03-04 12:00:00', 1, 0),
(3, '2021-03-06 16:00:00', 0, 0),
(4, '2021-04-05 09:00:00', 0, 0),
(5, '2021-04-05 09:15:00', 0, 0),
(6, '2021-04-05 09:30:00', 0, 0),
(7, '2021-04-05 09:45:00', 0, 0),
(8, '2021-04-05 10:00:00', 0, 0),
(9, '2021-04-05 10:15:00', 0, 0),
(5528, '2021-04-05 10:30:00', 0, 0),
(5529, '2021-04-05 10:45:00', 0, 0),
(5530, '2021-04-05 11:00:00', 0, 0),
(5531, '2021-04-05 11:15:00', 0, 0),
(5532, '2021-04-05 11:30:00', 0, 0),
(5533, '2021-04-05 11:45:00', 0, 0),
(5534, '2021-04-05 12:00:00', 0, 0),
(5535, '2021-04-05 14:00:00', 0, 0),
(5536, '2021-04-05 14:15:00', 0, 0),
(5537, '2021-04-05 14:30:00', 0, 0),
(5538, '2021-04-05 14:45:00', 0, 0),
(5539, '2021-04-05 15:00:00', 0, 0),
(5540, '2021-04-05 15:15:00', 0, 0),
(5541, '2021-04-05 15:30:00', 0, 0),
(5542, '2021-04-05 15:45:00', 0, 0),
(5543, '2021-04-05 16:00:00', 0, 0),
(5544, '2021-04-05 16:15:00', 0, 0),
(5545, '2021-04-05 16:30:00', 0, 0),
(5546, '2021-04-05 16:45:00', 0, 0),
(5547, '2021-04-05 17:00:00', 0, 0),
(5548, '2021-04-05 17:15:00', 0, 0),
(5549, '2021-04-05 17:30:00', 0, 0),
(5550, '2021-04-05 17:45:00', 0, 0),
(5551, '2021-04-06 09:00:00', 0, 0),
(5552, '2021-04-06 09:15:00', 0, 0),
(5553, '2021-04-06 09:30:00', 0, 0),
(5554, '2021-04-06 09:45:00', 0, 0),
(5555, '2021-04-06 10:00:00', 0, 0),
(5556, '2021-04-06 10:15:00', 0, 0),
(5557, '2021-04-06 10:30:00', 0, 0),
(5558, '2021-04-06 10:45:00', 0, 0),
(5559, '2021-04-06 11:00:00', 0, 0),
(5560, '2021-04-06 11:15:00', 0, 0),
(5561, '2021-04-06 11:30:00', 0, 0),
(5562, '2021-04-06 11:45:00', 0, 0),
(5563, '2021-04-06 12:00:00', 0, 0),
(5564, '2021-04-06 14:00:00', 0, 0),
(5565, '2021-04-06 14:15:00', 0, 0),
(5566, '2021-04-06 14:30:00', 0, 0),
(5567, '2021-04-06 14:45:00', 0, 0),
(5568, '2021-04-06 15:00:00', 0, 0),
(5569, '2021-04-06 15:15:00', 0, 0),
(5570, '2021-04-06 15:30:00', 0, 0),
(5571, '2021-04-06 15:45:00', 0, 0),
(5572, '2021-04-06 16:00:00', 0, 0),
(5573, '2021-04-06 16:15:00', 0, 0),
(5574, '2021-04-06 16:30:00', 0, 0),
(5575, '2021-04-06 16:45:00', 0, 0),
(5576, '2021-04-06 17:00:00', 0, 0),
(5577, '2021-04-06 17:15:00', 0, 0),
(5578, '2021-04-06 17:30:00', 0, 0),
(5579, '2021-04-06 17:45:00', 0, 0),
(5580, '2021-04-07 09:00:00', 0, 0),
(5581, '2021-04-07 09:15:00', 0, 0),
(5582, '2021-04-07 09:30:00', 0, 0),
(5583, '2021-04-07 09:45:00', 0, 0),
(5584, '2021-04-07 10:00:00', 0, 0),
(5585, '2021-04-07 10:15:00', 0, 0),
(5586, '2021-04-07 10:30:00', 0, 0),
(5587, '2021-04-07 10:45:00', 0, 0),
(5588, '2021-04-07 11:00:00', 0, 0),
(5589, '2021-04-07 11:15:00', 0, 0),
(5590, '2021-04-07 11:30:00', 0, 0),
(5591, '2021-04-07 11:45:00', 0, 0),
(5592, '2021-04-07 12:00:00', 0, 0),
(5593, '2021-04-07 14:00:00', 0, 0),
(5594, '2021-04-07 14:15:00', 0, 0),
(5595, '2021-04-07 14:30:00', 0, 0),
(5596, '2021-04-07 14:45:00', 0, 0),
(5597, '2021-04-07 15:00:00', 0, 0),
(5598, '2021-04-07 15:15:00', 0, 0),
(5599, '2021-04-07 15:30:00', 0, 0),
(5600, '2021-04-07 15:45:00', 0, 0),
(5601, '2021-04-07 16:00:00', 0, 0),
(5602, '2021-04-07 16:15:00', 0, 0),
(5603, '2021-04-07 16:30:00', 0, 0),
(5604, '2021-04-07 16:45:00', 0, 0),
(5605, '2021-04-07 17:00:00', 0, 0),
(5606, '2021-04-07 17:15:00', 0, 0),
(5607, '2021-04-07 17:30:00', 0, 0),
(5608, '2021-04-07 17:45:00', 0, 0),
(5609, '2021-04-08 09:00:00', 0, 0),
(5610, '2021-04-08 09:15:00', 0, 0),
(5611, '2021-04-08 09:30:00', 0, 0),
(5612, '2021-04-08 09:45:00', 0, 0),
(5613, '2021-04-08 10:00:00', 0, 0),
(5614, '2021-04-08 10:15:00', 0, 0),
(5615, '2021-04-08 10:30:00', 0, 0),
(5616, '2021-04-08 10:45:00', 0, 0),
(5617, '2021-04-08 11:00:00', 0, 0),
(5618, '2021-04-08 11:15:00', 0, 0),
(5619, '2021-04-08 11:30:00', 0, 0),
(5620, '2021-04-08 11:45:00', 0, 0),
(5621, '2021-04-08 12:00:00', 0, 0),
(5622, '2021-04-08 14:00:00', 0, 0),
(5623, '2021-04-08 14:15:00', 0, 0),
(5624, '2021-04-08 14:30:00', 0, 0),
(5625, '2021-04-08 14:45:00', 0, 0),
(5626, '2021-04-08 15:00:00', 0, 0),
(5627, '2021-04-08 15:15:00', 0, 0),
(5628, '2021-04-08 15:30:00', 0, 0),
(5629, '2021-04-08 15:45:00', 0, 0),
(5630, '2021-04-08 16:00:00', 0, 0),
(5631, '2021-04-08 16:15:00', 0, 0),
(5632, '2021-04-08 16:30:00', 0, 0),
(5633, '2021-04-08 16:45:00', 0, 0),
(5634, '2021-04-08 17:00:00', 0, 0),
(5635, '2021-04-08 17:15:00', 0, 0),
(5636, '2021-04-08 17:30:00', 0, 0),
(5637, '2021-04-08 17:45:00', 0, 0),
(5638, '2021-04-09 09:00:00', 0, 0),
(5639, '2021-04-09 09:15:00', 0, 0),
(5640, '2021-04-09 09:30:00', 0, 0),
(5641, '2021-04-09 09:45:00', 0, 0),
(5642, '2021-04-09 10:00:00', 0, 0),
(5643, '2021-04-09 10:15:00', 0, 0),
(5644, '2021-04-09 10:30:00', 0, 0),
(5645, '2021-04-09 10:45:00', 0, 0),
(5646, '2021-04-09 11:00:00', 0, 0),
(5647, '2021-04-09 11:15:00', 0, 0),
(5648, '2021-04-09 11:30:00', 0, 0),
(5649, '2021-04-09 11:45:00', 0, 0),
(5650, '2021-04-09 12:00:00', 0, 0),
(5651, '2021-04-09 14:00:00', 0, 0),
(5652, '2021-04-09 14:15:00', 0, 0),
(5653, '2021-04-09 14:30:00', 0, 0),
(5654, '2021-04-09 14:45:00', 0, 0),
(5655, '2021-04-09 15:00:00', 0, 0),
(5656, '2021-04-09 15:15:00', 0, 0),
(5657, '2021-04-09 15:30:00', 0, 0),
(5658, '2021-04-09 15:45:00', 0, 0),
(5659, '2021-04-09 16:00:00', 0, 0),
(5660, '2021-04-09 16:15:00', 0, 0),
(5661, '2021-04-09 16:30:00', 0, 0),
(5662, '2021-04-09 16:45:00', 0, 0),
(5663, '2021-04-09 17:00:00', 0, 0),
(5664, '2021-04-09 17:15:00', 0, 0),
(5665, '2021-04-09 17:30:00', 0, 0),
(5666, '2021-04-09 17:45:00', 0, 0),
(5667, '2021-04-12 09:00:00', 0, 0),
(5668, '2021-04-12 09:15:00', 0, 0),
(5669, '2021-04-12 09:30:00', 0, 0),
(5670, '2021-04-12 09:45:00', 0, 0),
(5671, '2021-04-12 10:00:00', 0, 0),
(5672, '2021-04-12 10:15:00', 0, 0),
(5673, '2021-04-12 10:30:00', 0, 0),
(5674, '2021-04-12 10:45:00', 0, 0),
(5675, '2021-04-12 11:00:00', 0, 0),
(5676, '2021-04-12 11:15:00', 0, 0),
(5677, '2021-04-12 11:30:00', 0, 0),
(5678, '2021-04-12 11:45:00', 0, 0),
(5679, '2021-04-12 12:00:00', 0, 0),
(5680, '2021-04-12 14:00:00', 0, 0),
(5681, '2021-04-12 14:15:00', 0, 0),
(5682, '2021-04-12 14:30:00', 0, 0),
(5683, '2021-04-12 14:45:00', 0, 0),
(5684, '2021-04-12 15:00:00', 0, 0),
(5685, '2021-04-12 15:15:00', 0, 0),
(5686, '2021-04-12 15:30:00', 0, 0),
(5687, '2021-04-12 15:45:00', 0, 0),
(5688, '2021-04-12 16:00:00', 0, 0),
(5689, '2021-04-12 16:15:00', 0, 0),
(5690, '2021-04-12 16:30:00', 0, 0),
(5691, '2021-04-12 16:45:00', 0, 0),
(5692, '2021-04-12 17:00:00', 0, 0),
(5693, '2021-04-12 17:15:00', 0, 0),
(5694, '2021-04-12 17:30:00', 0, 0),
(5695, '2021-04-12 17:45:00', 0, 0),
(5696, '2021-04-13 09:00:00', 0, 0),
(5697, '2021-04-13 09:15:00', 0, 0),
(5698, '2021-04-13 09:30:00', 0, 0),
(5699, '2021-04-13 09:45:00', 0, 0),
(5700, '2021-04-13 10:00:00', 0, 0),
(5701, '2021-04-13 10:15:00', 0, 0),
(5702, '2021-04-13 10:30:00', 0, 0),
(5703, '2021-04-13 10:45:00', 0, 0),
(5704, '2021-04-13 11:00:00', 0, 0),
(5705, '2021-04-13 11:15:00', 0, 0),
(5706, '2021-04-13 11:30:00', 0, 0),
(5707, '2021-04-13 11:45:00', 0, 0),
(5708, '2021-04-13 12:00:00', 0, 0),
(5709, '2021-04-13 14:00:00', 0, 0),
(5710, '2021-04-13 14:15:00', 0, 0),
(5711, '2021-04-13 14:30:00', 0, 0),
(5712, '2021-04-13 14:45:00', 0, 0),
(5713, '2021-04-13 15:00:00', 0, 0),
(5714, '2021-04-13 15:15:00', 0, 0),
(5715, '2021-04-13 15:30:00', 0, 0),
(5716, '2021-04-13 15:45:00', 0, 0),
(5717, '2021-04-13 16:00:00', 0, 0),
(5718, '2021-04-13 16:15:00', 0, 0),
(5719, '2021-04-13 16:30:00', 0, 0),
(5720, '2021-04-13 16:45:00', 0, 0),
(5721, '2021-04-13 17:00:00', 0, 0),
(5722, '2021-04-13 17:15:00', 0, 0),
(5723, '2021-04-13 17:30:00', 0, 0),
(5724, '2021-04-13 17:45:00', 0, 0),
(5725, '2021-04-14 09:00:00', 0, 0),
(5726, '2021-04-14 09:15:00', 0, 0),
(5727, '2021-04-14 09:30:00', 0, 0),
(5728, '2021-04-14 09:45:00', 0, 0),
(5729, '2021-04-14 10:00:00', 0, 0),
(5730, '2021-04-14 10:15:00', 0, 0),
(5731, '2021-04-14 10:30:00', 0, 0),
(5732, '2021-04-14 10:45:00', 0, 0),
(5733, '2021-04-14 11:00:00', 0, 0),
(5734, '2021-04-14 11:15:00', 0, 0),
(5735, '2021-04-14 11:30:00', 0, 0),
(5736, '2021-04-14 11:45:00', 0, 0),
(5737, '2021-04-14 12:00:00', 0, 0),
(5738, '2021-04-14 14:00:00', 0, 0),
(5739, '2021-04-14 14:15:00', 0, 0),
(5740, '2021-04-14 14:30:00', 0, 0),
(5741, '2021-04-14 14:45:00', 0, 0),
(5742, '2021-04-14 15:00:00', 0, 0),
(5743, '2021-04-14 15:15:00', 0, 0),
(5744, '2021-04-14 15:30:00', 0, 0),
(5745, '2021-04-14 15:45:00', 0, 0),
(5746, '2021-04-14 16:00:00', 0, 0),
(5747, '2021-04-14 16:15:00', 0, 0),
(5748, '2021-04-14 16:30:00', 0, 0),
(5749, '2021-04-14 16:45:00', 0, 0),
(5750, '2021-04-14 17:00:00', 0, 0),
(5751, '2021-04-14 17:15:00', 0, 0),
(5752, '2021-04-14 17:30:00', 0, 0),
(5753, '2021-04-14 17:45:00', 0, 0),
(5754, '2021-04-15 09:00:00', 0, 0),
(5755, '2021-04-15 09:15:00', 0, 0),
(5756, '2021-04-15 09:30:00', 0, 0),
(5757, '2021-04-15 09:45:00', 0, 0),
(5758, '2021-04-15 10:00:00', 0, 0),
(5759, '2021-04-15 10:15:00', 0, 0),
(5760, '2021-04-15 10:30:00', 0, 0),
(5761, '2021-04-15 10:45:00', 0, 0),
(5762, '2021-04-15 11:00:00', 0, 0),
(5763, '2021-04-15 11:15:00', 0, 0),
(5764, '2021-04-15 11:30:00', 0, 0),
(5765, '2021-04-15 11:45:00', 0, 0),
(5766, '2021-04-15 12:00:00', 0, 0),
(5767, '2021-04-15 14:00:00', 0, 0),
(5768, '2021-04-15 14:15:00', 0, 0),
(5769, '2021-04-15 14:30:00', 0, 0),
(5770, '2021-04-15 14:45:00', 0, 0),
(5771, '2021-04-15 15:00:00', 0, 0),
(5772, '2021-04-15 15:15:00', 0, 0),
(5773, '2021-04-15 15:30:00', 0, 0),
(5774, '2021-04-15 15:45:00', 0, 0),
(5775, '2021-04-15 16:00:00', 0, 0),
(5776, '2021-04-15 16:15:00', 0, 0),
(5777, '2021-04-15 16:30:00', 0, 0),
(5778, '2021-04-15 16:45:00', 0, 0),
(5779, '2021-04-15 17:00:00', 0, 0),
(5780, '2021-04-15 17:15:00', 0, 0),
(5781, '2021-04-15 17:30:00', 0, 0),
(5782, '2021-04-15 17:45:00', 0, 0),
(5783, '2021-04-16 09:00:00', 0, 0),
(5784, '2021-04-16 09:15:00', 0, 0),
(5785, '2021-04-16 09:30:00', 0, 0),
(5786, '2021-04-16 09:45:00', 0, 0),
(5787, '2021-04-16 10:00:00', 0, 0),
(5788, '2021-04-16 10:15:00', 0, 0),
(5789, '2021-04-16 10:30:00', 0, 0),
(5790, '2021-04-16 10:45:00', 0, 0),
(5791, '2021-04-16 11:00:00', 0, 0),
(5792, '2021-04-16 11:15:00', 0, 0),
(5793, '2021-04-16 11:30:00', 0, 0),
(5794, '2021-04-16 11:45:00', 0, 0),
(5795, '2021-04-16 12:00:00', 0, 0),
(5796, '2021-04-16 14:00:00', 0, 0),
(5797, '2021-04-16 14:15:00', 0, 0),
(5798, '2021-04-16 14:30:00', 0, 0),
(5799, '2021-04-16 14:45:00', 0, 0),
(5800, '2021-04-16 15:00:00', 0, 0),
(5801, '2021-04-16 15:15:00', 0, 0),
(5802, '2021-04-16 15:30:00', 0, 0),
(5803, '2021-04-16 15:45:00', 0, 0),
(5804, '2021-04-16 16:00:00', 0, 0),
(5805, '2021-04-16 16:15:00', 0, 0),
(5806, '2021-04-16 16:30:00', 0, 0),
(5807, '2021-04-16 16:45:00', 0, 0),
(5808, '2021-04-16 17:00:00', 0, 0),
(5809, '2021-04-16 17:15:00', 0, 0),
(5810, '2021-04-16 17:30:00', 0, 0),
(5811, '2021-04-16 17:45:00', 0, 0),
(5812, '2021-04-19 09:00:00', 0, 0),
(5813, '2021-04-19 09:15:00', 0, 0),
(5814, '2021-04-19 09:30:00', 0, 0),
(5815, '2021-04-19 09:45:00', 0, 0),
(5816, '2021-04-19 10:00:00', 0, 0),
(5817, '2021-04-19 10:15:00', 0, 0),
(5818, '2021-04-19 10:30:00', 0, 0),
(5819, '2021-04-19 10:45:00', 0, 0),
(5820, '2021-04-19 11:00:00', 0, 0),
(5821, '2021-04-19 11:15:00', 0, 0),
(5822, '2021-04-19 11:30:00', 0, 0),
(5823, '2021-04-19 11:45:00', 0, 0),
(5824, '2021-04-19 12:00:00', 0, 0),
(5825, '2021-04-19 14:00:00', 0, 0),
(5826, '2021-04-19 14:15:00', 0, 0),
(5827, '2021-04-19 14:30:00', 0, 0),
(5828, '2021-04-19 14:45:00', 0, 0),
(5829, '2021-04-19 15:00:00', 0, 0),
(5830, '2021-04-19 15:15:00', 0, 0),
(5831, '2021-04-19 15:30:00', 0, 0),
(5832, '2021-04-19 15:45:00', 0, 0),
(5833, '2021-04-19 16:00:00', 0, 0),
(5834, '2021-04-19 16:15:00', 0, 0),
(5835, '2021-04-19 16:30:00', 0, 0),
(5836, '2021-04-19 16:45:00', 0, 0),
(5837, '2021-04-19 17:00:00', 0, 0),
(5838, '2021-04-19 17:15:00', 0, 0),
(5839, '2021-04-19 17:30:00', 0, 0),
(5840, '2021-04-19 17:45:00', 0, 0),
(5841, '2021-04-20 09:00:00', 0, 0),
(5842, '2021-04-20 09:15:00', 0, 0),
(5843, '2021-04-20 09:30:00', 0, 0),
(5844, '2021-04-20 09:45:00', 0, 0),
(5845, '2021-04-20 10:00:00', 0, 0),
(5846, '2021-04-20 10:15:00', 0, 0),
(5847, '2021-04-20 10:30:00', 0, 0),
(5848, '2021-04-20 10:45:00', 0, 0),
(5849, '2021-04-20 11:00:00', 0, 0),
(5850, '2021-04-20 11:15:00', 0, 0),
(5851, '2021-04-20 11:30:00', 0, 0),
(5852, '2021-04-20 11:45:00', 0, 0),
(5853, '2021-04-20 12:00:00', 0, 0),
(5854, '2021-04-20 14:00:00', 0, 0),
(5855, '2021-04-20 14:15:00', 0, 0),
(5856, '2021-04-20 14:30:00', 0, 0),
(5857, '2021-04-20 14:45:00', 0, 0),
(5858, '2021-04-20 15:00:00', 0, 0),
(5859, '2021-04-20 15:15:00', 0, 0),
(5860, '2021-04-20 15:30:00', 0, 0),
(5861, '2021-04-20 15:45:00', 0, 0),
(5862, '2021-04-20 16:00:00', 0, 0),
(5863, '2021-04-20 16:15:00', 0, 0),
(5864, '2021-04-20 16:30:00', 0, 0),
(5865, '2021-04-20 16:45:00', 0, 0),
(5866, '2021-04-20 17:00:00', 0, 0),
(5867, '2021-04-20 17:15:00', 0, 0),
(5868, '2021-04-20 17:30:00', 0, 0),
(5869, '2021-04-20 17:45:00', 0, 0),
(5870, '2021-04-21 09:00:00', 0, 0),
(5871, '2021-04-21 09:15:00', 0, 0),
(5872, '2021-04-21 09:30:00', 0, 0),
(5873, '2021-04-21 09:45:00', 0, 0),
(5874, '2021-04-21 10:00:00', 0, 0),
(5875, '2021-04-21 10:15:00', 0, 0),
(5876, '2021-04-21 10:30:00', 0, 0),
(5877, '2021-04-21 10:45:00', 0, 0),
(5878, '2021-04-21 11:00:00', 0, 0),
(5879, '2021-04-21 11:15:00', 0, 0),
(5880, '2021-04-21 11:30:00', 0, 0),
(5881, '2021-04-21 11:45:00', 0, 0),
(5882, '2021-04-21 12:00:00', 0, 0),
(5883, '2021-04-21 14:00:00', 0, 0),
(5884, '2021-04-21 14:15:00', 0, 0),
(5885, '2021-04-21 14:30:00', 0, 0),
(5886, '2021-04-21 14:45:00', 0, 0),
(5887, '2021-04-21 15:00:00', 0, 0),
(5888, '2021-04-21 15:15:00', 0, 0),
(5889, '2021-04-21 15:30:00', 0, 0),
(5890, '2021-04-21 15:45:00', 0, 0),
(5891, '2021-04-21 16:00:00', 0, 0),
(5892, '2021-04-21 16:15:00', 0, 0),
(5893, '2021-04-21 16:30:00', 0, 0),
(5894, '2021-04-21 16:45:00', 0, 0),
(5895, '2021-04-21 17:00:00', 0, 0),
(5896, '2021-04-21 17:15:00', 0, 0),
(5897, '2021-04-21 17:30:00', 0, 0),
(5898, '2021-04-21 17:45:00', 0, 0),
(5899, '2021-04-22 09:00:00', 0, 0),
(5900, '2021-04-22 09:15:00', 0, 0),
(5901, '2021-04-22 09:30:00', 0, 0),
(5902, '2021-04-22 09:45:00', 0, 0),
(5903, '2021-04-22 10:00:00', 0, 0),
(5904, '2021-04-22 10:15:00', 0, 0),
(5905, '2021-04-22 10:30:00', 0, 0),
(5906, '2021-04-22 10:45:00', 0, 0),
(5907, '2021-04-22 11:00:00', 0, 0),
(5908, '2021-04-22 11:15:00', 0, 0),
(5909, '2021-04-22 11:30:00', 0, 0),
(5910, '2021-04-22 11:45:00', 0, 0),
(5911, '2021-04-22 12:00:00', 0, 0),
(5912, '2021-04-22 14:00:00', 0, 0),
(5913, '2021-04-22 14:15:00', 0, 0),
(5914, '2021-04-22 14:30:00', 0, 0),
(5915, '2021-04-22 14:45:00', 0, 0),
(5916, '2021-04-22 15:00:00', 0, 0),
(5917, '2021-04-22 15:15:00', 0, 0),
(5918, '2021-04-22 15:30:00', 0, 0),
(5919, '2021-04-22 15:45:00', 0, 0),
(5920, '2021-04-22 16:00:00', 0, 0),
(5921, '2021-04-22 16:15:00', 0, 0),
(5922, '2021-04-22 16:30:00', 0, 0),
(5923, '2021-04-22 16:45:00', 0, 0),
(5924, '2021-04-22 17:00:00', 0, 0),
(5925, '2021-04-22 17:15:00', 0, 0),
(5926, '2021-04-22 17:30:00', 0, 0),
(5927, '2021-04-22 17:45:00', 0, 0),
(5928, '2021-04-23 09:00:00', 0, 0),
(5929, '2021-04-23 09:15:00', 0, 0),
(5930, '2021-04-23 09:30:00', 0, 0),
(5931, '2021-04-23 09:45:00', 0, 0),
(5932, '2021-04-23 10:00:00', 0, 0),
(5933, '2021-04-23 10:15:00', 0, 0),
(5934, '2021-04-23 10:30:00', 0, 0),
(5935, '2021-04-23 10:45:00', 0, 0),
(5936, '2021-04-23 11:00:00', 0, 0),
(5937, '2021-04-23 11:15:00', 0, 0),
(5938, '2021-04-23 11:30:00', 0, 0),
(5939, '2021-04-23 11:45:00', 0, 0),
(5940, '2021-04-23 12:00:00', 0, 0),
(5941, '2021-04-23 14:00:00', 0, 0),
(5942, '2021-04-23 14:15:00', 0, 0),
(5943, '2021-04-23 14:30:00', 0, 0),
(5944, '2021-04-23 14:45:00', 0, 0),
(5945, '2021-04-23 15:00:00', 0, 0),
(5946, '2021-04-23 15:15:00', 0, 0),
(5947, '2021-04-23 15:30:00', 0, 0),
(5948, '2021-04-23 15:45:00', 0, 0),
(5949, '2021-04-23 16:00:00', 0, 0),
(5950, '2021-04-23 16:15:00', 0, 0),
(5951, '2021-04-23 16:30:00', 0, 0),
(5952, '2021-04-23 16:45:00', 0, 0),
(5953, '2021-04-23 17:00:00', 0, 0),
(5954, '2021-04-23 17:15:00', 0, 0),
(5955, '2021-04-23 17:30:00', 0, 0),
(5956, '2021-04-23 17:45:00', 0, 0),
(5957, '2021-04-26 09:00:00', 0, 0),
(5958, '2021-04-26 09:15:00', 0, 0),
(5959, '2021-04-26 09:30:00', 0, 0),
(5960, '2021-04-26 09:45:00', 0, 0),
(5961, '2021-04-26 10:00:00', 0, 0),
(5962, '2021-04-26 10:15:00', 0, 0),
(5963, '2021-04-26 10:30:00', 0, 0),
(5964, '2021-04-26 10:45:00', 0, 0),
(5965, '2021-04-26 11:00:00', 0, 0),
(5966, '2021-04-26 11:15:00', 0, 0),
(5967, '2021-04-26 11:30:00', 0, 0),
(5968, '2021-04-26 11:45:00', 0, 0),
(5969, '2021-04-26 12:00:00', 0, 0),
(5970, '2021-04-26 14:00:00', 0, 0),
(5971, '2021-04-26 14:15:00', 0, 0),
(5972, '2021-04-26 14:30:00', 0, 0),
(5973, '2021-04-26 14:45:00', 0, 0),
(5974, '2021-04-26 15:00:00', 0, 0),
(5975, '2021-04-26 15:15:00', 0, 0),
(5976, '2021-04-26 15:30:00', 0, 0),
(5977, '2021-04-26 15:45:00', 0, 0),
(5978, '2021-04-26 16:00:00', 0, 0),
(5979, '2021-04-26 16:15:00', 0, 0),
(5980, '2021-04-26 16:30:00', 0, 0),
(5981, '2021-04-26 16:45:00', 0, 0),
(5982, '2021-04-26 17:00:00', 0, 0),
(5983, '2021-04-26 17:15:00', 0, 0),
(5984, '2021-04-26 17:30:00', 0, 0),
(5985, '2021-04-26 17:45:00', 0, 0),
(5986, '2021-04-27 09:00:00', 0, 0),
(5987, '2021-04-27 09:15:00', 0, 0),
(5988, '2021-04-27 09:30:00', 0, 0),
(5989, '2021-04-27 09:45:00', 0, 0),
(5990, '2021-04-27 10:00:00', 0, 0),
(5991, '2021-04-27 10:15:00', 0, 0),
(5992, '2021-04-27 10:30:00', 0, 0),
(5993, '2021-04-27 10:45:00', 0, 0),
(5994, '2021-04-27 11:00:00', 0, 0),
(5995, '2021-04-27 11:15:00', 0, 0),
(5996, '2021-04-27 11:30:00', 0, 0),
(5997, '2021-04-27 11:45:00', 0, 0),
(5998, '2021-04-27 12:00:00', 0, 0),
(5999, '2021-04-27 14:00:00', 0, 0),
(6000, '2021-04-27 14:15:00', 0, 0),
(6001, '2021-04-27 14:30:00', 0, 0),
(6002, '2021-04-27 14:45:00', 0, 0),
(6003, '2021-04-27 15:00:00', 0, 0),
(6004, '2021-04-27 15:15:00', 0, 0),
(6005, '2021-04-27 15:30:00', 0, 0),
(6006, '2021-04-27 15:45:00', 0, 0),
(6007, '2021-04-27 16:00:00', 0, 0),
(6008, '2021-04-27 16:15:00', 0, 0),
(6009, '2021-04-27 16:30:00', 0, 0),
(6010, '2021-04-27 16:45:00', 0, 0),
(6011, '2021-04-27 17:00:00', 0, 0),
(6012, '2021-04-27 17:15:00', 0, 0),
(6013, '2021-04-27 17:30:00', 0, 0),
(6014, '2021-04-27 17:45:00', 0, 0),
(6015, '2021-04-28 09:00:00', 0, 0),
(6016, '2021-04-28 09:15:00', 0, 0),
(6017, '2021-04-28 09:30:00', 0, 0),
(6018, '2021-04-28 09:45:00', 0, 0),
(6019, '2021-04-28 10:00:00', 0, 0),
(6020, '2021-04-28 10:15:00', 0, 0),
(6021, '2021-04-28 10:30:00', 0, 0),
(6022, '2021-04-28 10:45:00', 0, 0),
(6023, '2021-04-28 11:00:00', 0, 0),
(6024, '2021-04-28 11:15:00', 0, 0),
(6025, '2021-04-28 11:30:00', 0, 0),
(6026, '2021-04-28 11:45:00', 0, 0),
(6027, '2021-04-28 12:00:00', 0, 0),
(6028, '2021-04-28 14:00:00', 0, 0),
(6029, '2021-04-28 14:15:00', 0, 0),
(6030, '2021-04-28 14:30:00', 0, 0),
(6031, '2021-04-28 14:45:00', 0, 0),
(6032, '2021-04-28 15:00:00', 0, 0),
(6033, '2021-04-28 15:15:00', 0, 0),
(6034, '2021-04-28 15:30:00', 0, 0),
(6035, '2021-04-28 15:45:00', 0, 0),
(6036, '2021-04-28 16:00:00', 0, 0),
(6037, '2021-04-28 16:15:00', 0, 0),
(6038, '2021-04-28 16:30:00', 0, 0),
(6039, '2021-04-28 16:45:00', 0, 0),
(6040, '2021-04-28 17:00:00', 0, 0),
(6041, '2021-04-28 17:15:00', 0, 0),
(6042, '2021-04-28 17:30:00', 0, 0),
(6043, '2021-04-28 17:45:00', 0, 0),
(6044, '2021-04-29 09:00:00', 0, 0),
(6045, '2021-04-29 09:15:00', 0, 0),
(6046, '2021-04-29 09:30:00', 0, 0),
(6047, '2021-04-29 09:45:00', 0, 0),
(6048, '2021-04-29 10:00:00', 0, 0),
(6049, '2021-04-29 10:15:00', 0, 0),
(6050, '2021-04-29 10:30:00', 0, 0),
(6051, '2021-04-29 10:45:00', 0, 0),
(6052, '2021-04-29 11:00:00', 0, 0),
(6053, '2021-04-29 11:15:00', 0, 0),
(6054, '2021-04-29 11:30:00', 0, 0),
(6055, '2021-04-29 11:45:00', 0, 0),
(6056, '2021-04-29 12:00:00', 0, 0),
(6057, '2021-04-29 14:00:00', 0, 0),
(6058, '2021-04-29 14:15:00', 0, 0),
(6059, '2021-04-29 14:30:00', 0, 0),
(6060, '2021-04-29 14:45:00', 0, 0),
(6061, '2021-04-29 15:00:00', 0, 0),
(6062, '2021-04-29 15:15:00', 0, 0),
(6063, '2021-04-29 15:30:00', 0, 0),
(6064, '2021-04-29 15:45:00', 0, 0),
(6065, '2021-04-29 16:00:00', 0, 0),
(6066, '2021-04-29 16:15:00', 0, 0),
(6067, '2021-04-29 16:30:00', 0, 0),
(6068, '2021-04-29 16:45:00', 0, 0),
(6069, '2021-04-29 17:00:00', 0, 0),
(6070, '2021-04-29 17:15:00', 0, 0),
(6071, '2021-04-29 17:30:00', 0, 0),
(6072, '2021-04-29 17:45:00', 0, 0),
(6073, '2021-04-30 09:00:00', 0, 0),
(6074, '2021-04-30 09:15:00', 0, 0),
(6075, '2021-04-30 09:30:00', 0, 0),
(6076, '2021-04-30 09:45:00', 0, 0),
(6077, '2021-04-30 10:00:00', 0, 0),
(6078, '2021-04-30 10:15:00', 0, 0),
(6079, '2021-04-30 10:30:00', 0, 0),
(6080, '2021-04-30 10:45:00', 0, 0),
(6081, '2021-04-30 11:00:00', 0, 0),
(6082, '2021-04-30 11:15:00', 0, 0),
(6083, '2021-04-30 11:30:00', 0, 0),
(6084, '2021-04-30 11:45:00', 0, 0),
(6085, '2021-04-30 12:00:00', 0, 0),
(6086, '2021-04-30 14:00:00', 0, 0),
(6087, '2021-04-30 14:15:00', 0, 0),
(6088, '2021-04-30 14:30:00', 0, 0),
(6089, '2021-04-30 14:45:00', 0, 0),
(6090, '2021-04-30 15:00:00', 0, 0),
(6091, '2021-04-30 15:15:00', 0, 0),
(6092, '2021-04-30 15:30:00', 0, 0),
(6093, '2021-04-30 15:45:00', 0, 0),
(6094, '2021-04-30 16:00:00', 0, 0),
(6095, '2021-04-30 16:15:00', 0, 0),
(6096, '2021-04-30 16:30:00', 0, 0),
(6097, '2021-04-30 16:45:00', 0, 0),
(6098, '2021-04-30 17:00:00', 0, 0),
(6099, '2021-04-30 17:15:00', 0, 0),
(6100, '2021-04-30 17:30:00', 0, 0),
(6101, '2021-04-30 17:45:00', 0, 0),
(6218, '2021-05-03 09:00:00', 0, 0),
(6219, '2021-05-03 09:15:00', 0, 0),
(6220, '2021-05-03 09:30:00', 0, 0),
(6221, '2021-05-03 09:45:00', 0, 0),
(6222, '2021-05-03 10:00:00', 0, 0),
(6223, '2021-05-03 10:15:00', 0, 0),
(6224, '2021-05-03 10:30:00', 0, 0),
(6225, '2021-05-03 10:45:00', 0, 0),
(6226, '2021-05-03 11:00:00', 0, 0),
(6227, '2021-05-03 11:15:00', 0, 0),
(6228, '2021-05-03 11:30:00', 0, 0),
(6229, '2021-05-03 11:45:00', 0, 0),
(6230, '2021-05-03 12:00:00', 0, 0),
(6231, '2021-05-03 14:00:00', 0, 0),
(6232, '2021-05-03 14:15:00', 0, 0),
(6233, '2021-05-03 14:30:00', 0, 0),
(6234, '2021-05-03 14:45:00', 0, 0),
(6235, '2021-05-03 15:00:00', 0, 0),
(6236, '2021-05-03 15:15:00', 0, 0),
(6237, '2021-05-03 15:30:00', 0, 0),
(6238, '2021-05-03 15:45:00', 0, 0),
(6239, '2021-05-03 16:00:00', 0, 0),
(6240, '2021-05-03 16:15:00', 0, 0),
(6241, '2021-05-03 16:30:00', 0, 0),
(6242, '2021-05-03 16:45:00', 0, 0),
(6243, '2021-05-03 17:00:00', 0, 0),
(6244, '2021-05-03 17:15:00', 0, 0),
(6245, '2021-05-03 17:30:00', 0, 0),
(6246, '2021-05-03 17:45:00', 0, 0),
(6247, '2021-05-04 09:00:00', 0, 0),
(6248, '2021-05-04 09:15:00', 0, 0),
(6249, '2021-05-04 09:30:00', 0, 0),
(6250, '2021-05-04 09:45:00', 0, 0),
(6251, '2021-05-04 10:00:00', 0, 0),
(6252, '2021-05-04 10:15:00', 0, 0),
(6253, '2021-05-04 10:30:00', 0, 0),
(6254, '2021-05-04 10:45:00', 0, 0),
(6255, '2021-05-04 11:00:00', 0, 0),
(6256, '2021-05-04 11:15:00', 0, 0),
(6257, '2021-05-04 11:30:00', 0, 0),
(6258, '2021-05-04 11:45:00', 0, 0),
(6259, '2021-05-04 12:00:00', 0, 0),
(6260, '2021-05-04 14:00:00', 0, 0),
(6261, '2021-05-04 14:15:00', 0, 0),
(6262, '2021-05-04 14:30:00', 0, 0),
(6263, '2021-05-04 14:45:00', 0, 0),
(6264, '2021-05-04 15:00:00', 0, 0),
(6265, '2021-05-04 15:15:00', 0, 0),
(6266, '2021-05-04 15:30:00', 0, 0),
(6267, '2021-05-04 15:45:00', 0, 0),
(6268, '2021-05-04 16:00:00', 0, 0),
(6269, '2021-05-04 16:15:00', 0, 0),
(6270, '2021-05-04 16:30:00', 0, 0),
(6271, '2021-05-04 16:45:00', 0, 0),
(6272, '2021-05-04 17:00:00', 0, 0),
(6273, '2021-05-04 17:15:00', 0, 0),
(6274, '2021-05-04 17:30:00', 0, 0),
(6275, '2021-05-04 17:45:00', 0, 0),
(6276, '2021-05-05 09:00:00', 0, 0),
(6277, '2021-05-05 09:15:00', 0, 0),
(6278, '2021-05-05 09:30:00', 0, 0),
(6279, '2021-05-05 09:45:00', 0, 0),
(6280, '2021-05-05 10:00:00', 0, 0),
(6281, '2021-05-05 10:15:00', 0, 0),
(6282, '2021-05-05 10:30:00', 0, 0),
(6283, '2021-05-05 10:45:00', 0, 0),
(6284, '2021-05-05 11:00:00', 0, 0),
(6285, '2021-05-05 11:15:00', 0, 0),
(6286, '2021-05-05 11:30:00', 0, 0),
(6287, '2021-05-05 11:45:00', 0, 0),
(6288, '2021-05-05 12:00:00', 0, 0),
(6289, '2021-05-05 14:00:00', 0, 0),
(6290, '2021-05-05 14:15:00', 0, 0),
(6291, '2021-05-05 14:30:00', 0, 0),
(6292, '2021-05-05 14:45:00', 0, 0),
(6293, '2021-05-05 15:00:00', 0, 0),
(6294, '2021-05-05 15:15:00', 0, 0),
(6295, '2021-05-05 15:30:00', 0, 0),
(6296, '2021-05-05 15:45:00', 0, 0),
(6297, '2021-05-05 16:00:00', 0, 0),
(6298, '2021-05-05 16:15:00', 0, 0),
(6299, '2021-05-05 16:30:00', 0, 0),
(6300, '2021-05-05 16:45:00', 0, 0),
(6301, '2021-05-05 17:00:00', 0, 0),
(6302, '2021-05-05 17:15:00', 0, 0),
(6303, '2021-05-05 17:30:00', 0, 0),
(6304, '2021-05-05 17:45:00', 0, 0),
(6305, '2021-05-06 09:00:00', 0, 0),
(6306, '2021-05-06 09:15:00', 0, 0),
(6307, '2021-05-06 09:30:00', 0, 0),
(6308, '2021-05-06 09:45:00', 0, 0),
(6309, '2021-05-06 10:00:00', 0, 0),
(6310, '2021-05-06 10:15:00', 0, 0),
(6311, '2021-05-06 10:30:00', 0, 0),
(6312, '2021-05-06 10:45:00', 0, 0),
(6313, '2021-05-06 11:00:00', 0, 0),
(6314, '2021-05-06 11:15:00', 0, 0),
(6315, '2021-05-06 11:30:00', 0, 0),
(6316, '2021-05-06 11:45:00', 0, 0),
(6317, '2021-05-06 12:00:00', 0, 0),
(6318, '2021-05-06 14:00:00', 0, 0),
(6319, '2021-05-06 14:15:00', 0, 0),
(6320, '2021-05-06 14:30:00', 0, 0),
(6321, '2021-05-06 14:45:00', 0, 0),
(6322, '2021-05-06 15:00:00', 0, 0),
(6323, '2021-05-06 15:15:00', 0, 0),
(6324, '2021-05-06 15:30:00', 0, 0),
(6325, '2021-05-06 15:45:00', 0, 0),
(6326, '2021-05-06 16:00:00', 0, 0),
(6327, '2021-05-06 16:15:00', 0, 0),
(6328, '2021-05-06 16:30:00', 0, 0),
(6329, '2021-05-06 16:45:00', 0, 0),
(6330, '2021-05-06 17:00:00', 0, 0),
(6331, '2021-05-06 17:15:00', 0, 0),
(6332, '2021-05-06 17:30:00', 0, 0),
(6333, '2021-05-06 17:45:00', 0, 0),
(6334, '2021-05-07 09:00:00', 0, 0),
(6335, '2021-05-07 09:15:00', 0, 0),
(6336, '2021-05-07 09:30:00', 0, 0),
(6337, '2021-05-07 09:45:00', 0, 0),
(6338, '2021-05-07 10:00:00', 0, 0),
(6339, '2021-05-07 10:15:00', 0, 0),
(6340, '2021-05-07 10:30:00', 0, 0),
(6341, '2021-05-07 10:45:00', 0, 0),
(6342, '2021-05-07 11:00:00', 0, 0),
(6343, '2021-05-07 11:15:00', 0, 0),
(6344, '2021-05-07 11:30:00', 0, 0),
(6345, '2021-05-07 11:45:00', 0, 0),
(6346, '2021-05-07 12:00:00', 0, 0),
(6347, '2021-05-07 14:00:00', 0, 0),
(6348, '2021-05-07 14:15:00', 0, 0),
(6349, '2021-05-07 14:30:00', 0, 0),
(6350, '2021-05-07 14:45:00', 0, 0),
(6351, '2021-05-07 15:00:00', 0, 0),
(6352, '2021-05-07 15:15:00', 0, 0),
(6353, '2021-05-07 15:30:00', 0, 0),
(6354, '2021-05-07 15:45:00', 0, 0),
(6355, '2021-05-07 16:00:00', 0, 0),
(6356, '2021-05-07 16:15:00', 0, 0),
(6357, '2021-05-07 16:30:00', 0, 0),
(6358, '2021-05-07 16:45:00', 0, 0),
(6359, '2021-05-07 17:00:00', 0, 0),
(6360, '2021-05-07 17:15:00', 0, 0),
(6361, '2021-05-07 17:30:00', 0, 0),
(6362, '2021-05-07 17:45:00', 0, 0),
(6363, '2021-05-10 09:00:00', 0, 0),
(6364, '2021-05-10 09:15:00', 0, 0),
(6365, '2021-05-10 09:30:00', 0, 0),
(6366, '2021-05-10 09:45:00', 0, 0),
(6367, '2021-05-10 10:00:00', 0, 0),
(6368, '2021-05-10 10:15:00', 0, 0),
(6369, '2021-05-10 10:30:00', 0, 0),
(6370, '2021-05-10 10:45:00', 0, 0),
(6371, '2021-05-10 11:00:00', 0, 0),
(6372, '2021-05-10 11:15:00', 0, 0),
(6373, '2021-05-10 11:30:00', 0, 0),
(6374, '2021-05-10 11:45:00', 0, 0),
(6375, '2021-05-10 12:00:00', 0, 0),
(6376, '2021-05-10 14:00:00', 0, 0),
(6377, '2021-05-10 14:15:00', 0, 0),
(6378, '2021-05-10 14:30:00', 0, 0),
(6379, '2021-05-10 14:45:00', 0, 0),
(6380, '2021-05-10 15:00:00', 0, 0),
(6381, '2021-05-10 15:15:00', 0, 0),
(6382, '2021-05-10 15:30:00', 0, 0),
(6383, '2021-05-10 15:45:00', 0, 0),
(6384, '2021-05-10 16:00:00', 0, 0),
(6385, '2021-05-10 16:15:00', 0, 0),
(6386, '2021-05-10 16:30:00', 0, 0),
(6387, '2021-05-10 16:45:00', 0, 0),
(6388, '2021-05-10 17:00:00', 0, 0),
(6389, '2021-05-10 17:15:00', 0, 0),
(6390, '2021-05-10 17:30:00', 0, 0),
(6391, '2021-05-10 17:45:00', 0, 0),
(6392, '2021-05-11 09:00:00', 0, 0),
(6393, '2021-05-11 09:15:00', 0, 0),
(6394, '2021-05-11 09:30:00', 0, 0),
(6395, '2021-05-11 09:45:00', 0, 0),
(6396, '2021-05-11 10:00:00', 0, 0),
(6397, '2021-05-11 10:15:00', 0, 0),
(6398, '2021-05-11 10:30:00', 0, 0),
(6399, '2021-05-11 10:45:00', 0, 0),
(6400, '2021-05-11 11:00:00', 0, 0),
(6401, '2021-05-11 11:15:00', 0, 0),
(6402, '2021-05-11 11:30:00', 0, 0),
(6403, '2021-05-11 11:45:00', 0, 0),
(6404, '2021-05-11 12:00:00', 0, 0),
(6405, '2021-05-11 14:00:00', 0, 0),
(6406, '2021-05-11 14:15:00', 0, 0),
(6407, '2021-05-11 14:30:00', 0, 0),
(6408, '2021-05-11 14:45:00', 0, 0),
(6409, '2021-05-11 15:00:00', 0, 0),
(6410, '2021-05-11 15:15:00', 0, 0),
(6411, '2021-05-11 15:30:00', 0, 0),
(6412, '2021-05-11 15:45:00', 0, 0),
(6413, '2021-05-11 16:00:00', 0, 0),
(6414, '2021-05-11 16:15:00', 0, 0),
(6415, '2021-05-11 16:30:00', 0, 0),
(6416, '2021-05-11 16:45:00', 0, 0),
(6417, '2021-05-11 17:00:00', 0, 0),
(6418, '2021-05-11 17:15:00', 0, 0),
(6419, '2021-05-11 17:30:00', 0, 0),
(6420, '2021-05-11 17:45:00', 0, 0),
(6421, '2021-05-12 09:00:00', 0, 0),
(6422, '2021-05-12 09:15:00', 0, 0),
(6423, '2021-05-12 09:30:00', 0, 0),
(6424, '2021-05-12 09:45:00', 0, 0),
(6425, '2021-05-12 10:00:00', 0, 0),
(6426, '2021-05-12 10:15:00', 0, 0),
(6427, '2021-05-12 10:30:00', 0, 0),
(6428, '2021-05-12 10:45:00', 0, 0),
(6429, '2021-05-12 11:00:00', 0, 0),
(6430, '2021-05-12 11:15:00', 0, 0),
(6431, '2021-05-12 11:30:00', 0, 0),
(6432, '2021-05-12 11:45:00', 0, 0),
(6433, '2021-05-12 12:00:00', 0, 0),
(6434, '2021-05-12 14:00:00', 0, 0),
(6435, '2021-05-12 14:15:00', 0, 0),
(6436, '2021-05-12 14:30:00', 0, 0),
(6437, '2021-05-12 14:45:00', 0, 0),
(6438, '2021-05-12 15:00:00', 0, 0),
(6439, '2021-05-12 15:15:00', 0, 0),
(6440, '2021-05-12 15:30:00', 0, 0),
(6441, '2021-05-12 15:45:00', 0, 0),
(6442, '2021-05-12 16:00:00', 0, 0),
(6443, '2021-05-12 16:15:00', 0, 0),
(6444, '2021-05-12 16:30:00', 0, 0),
(6445, '2021-05-12 16:45:00', 0, 0),
(6446, '2021-05-12 17:00:00', 0, 0),
(6447, '2021-05-12 17:15:00', 0, 0),
(6448, '2021-05-12 17:30:00', 0, 0),
(6449, '2021-05-12 17:45:00', 0, 0),
(6450, '2021-05-13 09:00:00', 0, 0),
(6451, '2021-05-13 09:15:00', 0, 0),
(6452, '2021-05-13 09:30:00', 0, 0),
(6453, '2021-05-13 09:45:00', 0, 0),
(6454, '2021-05-13 10:00:00', 0, 0),
(6455, '2021-05-13 10:15:00', 0, 0),
(6456, '2021-05-13 10:30:00', 0, 0),
(6457, '2021-05-13 10:45:00', 0, 0),
(6458, '2021-05-13 11:00:00', 0, 0),
(6459, '2021-05-13 11:15:00', 0, 0),
(6460, '2021-05-13 11:30:00', 0, 0),
(6461, '2021-05-13 11:45:00', 0, 0),
(6462, '2021-05-13 12:00:00', 0, 0),
(6463, '2021-05-13 14:00:00', 0, 0),
(6464, '2021-05-13 14:15:00', 0, 0),
(6465, '2021-05-13 14:30:00', 0, 0),
(6466, '2021-05-13 14:45:00', 0, 0),
(6467, '2021-05-13 15:00:00', 0, 0),
(6468, '2021-05-13 15:15:00', 0, 0),
(6469, '2021-05-13 15:30:00', 0, 0),
(6470, '2021-05-13 15:45:00', 0, 0),
(6471, '2021-05-13 16:00:00', 0, 0),
(6472, '2021-05-13 16:15:00', 0, 0),
(6473, '2021-05-13 16:30:00', 0, 0),
(6474, '2021-05-13 16:45:00', 0, 0),
(6475, '2021-05-13 17:00:00', 0, 0),
(6476, '2021-05-13 17:15:00', 0, 0),
(6477, '2021-05-13 17:30:00', 0, 0),
(6478, '2021-05-13 17:45:00', 0, 0),
(6479, '2021-05-14 09:00:00', 0, 0),
(6480, '2021-05-14 09:15:00', 0, 0),
(6481, '2021-05-14 09:30:00', 0, 0),
(6482, '2021-05-14 09:45:00', 0, 0),
(6483, '2021-05-14 10:00:00', 0, 0),
(6484, '2021-05-14 10:15:00', 0, 0),
(6485, '2021-05-14 10:30:00', 0, 0),
(6486, '2021-05-14 10:45:00', 0, 0),
(6487, '2021-05-14 11:00:00', 0, 0),
(6488, '2021-05-14 11:15:00', 0, 0),
(6489, '2021-05-14 11:30:00', 0, 0),
(6490, '2021-05-14 11:45:00', 0, 0),
(6491, '2021-05-14 12:00:00', 0, 0),
(6492, '2021-05-14 14:00:00', 0, 0),
(6493, '2021-05-14 14:15:00', 0, 0),
(6494, '2021-05-14 14:30:00', 0, 0),
(6495, '2021-05-14 14:45:00', 0, 0),
(6496, '2021-05-14 15:00:00', 0, 0),
(6497, '2021-05-14 15:15:00', 0, 0),
(6498, '2021-05-14 15:30:00', 0, 0),
(6499, '2021-05-14 15:45:00', 0, 0),
(6500, '2021-05-14 16:00:00', 0, 0),
(6501, '2021-05-14 16:15:00', 0, 0),
(6502, '2021-05-14 16:30:00', 0, 0),
(6503, '2021-05-14 16:45:00', 0, 0),
(6504, '2021-05-14 17:00:00', 0, 0),
(6505, '2021-05-14 17:15:00', 0, 0),
(6506, '2021-05-14 17:30:00', 0, 0),
(6507, '2021-05-14 17:45:00', 0, 0),
(6508, '2021-05-17 09:00:00', 0, 0),
(6509, '2021-05-17 09:15:00', 0, 0),
(6510, '2021-05-17 09:30:00', 0, 0),
(6511, '2021-05-17 09:45:00', 0, 0),
(6512, '2021-05-17 10:00:00', 0, 0),
(6513, '2021-05-17 10:15:00', 0, 0),
(6514, '2021-05-17 10:30:00', 0, 0),
(6515, '2021-05-17 10:45:00', 0, 0),
(6516, '2021-05-17 11:00:00', 0, 0),
(6517, '2021-05-17 11:15:00', 0, 0),
(6518, '2021-05-17 11:30:00', 0, 0),
(6519, '2021-05-17 11:45:00', 0, 0),
(6520, '2021-05-17 12:00:00', 0, 0),
(6521, '2021-05-17 14:00:00', 0, 0),
(6522, '2021-05-17 14:15:00', 0, 0),
(6523, '2021-05-17 14:30:00', 0, 0),
(6524, '2021-05-17 14:45:00', 0, 0),
(6525, '2021-05-17 15:00:00', 0, 0),
(6526, '2021-05-17 15:15:00', 0, 0),
(6527, '2021-05-17 15:30:00', 0, 0),
(6528, '2021-05-17 15:45:00', 0, 0),
(6529, '2021-05-17 16:00:00', 0, 0),
(6530, '2021-05-17 16:15:00', 0, 0),
(6531, '2021-05-17 16:30:00', 0, 0),
(6532, '2021-05-17 16:45:00', 0, 0),
(6533, '2021-05-17 17:00:00', 0, 0),
(6534, '2021-05-17 17:15:00', 0, 0),
(6535, '2021-05-17 17:30:00', 0, 0),
(6536, '2021-05-17 17:45:00', 0, 0),
(6537, '2021-05-18 09:00:00', 0, 0),
(6538, '2021-05-18 09:15:00', 0, 0),
(6539, '2021-05-18 09:30:00', 0, 0),
(6540, '2021-05-18 09:45:00', 0, 0),
(6541, '2021-05-18 10:00:00', 0, 0),
(6542, '2021-05-18 10:15:00', 0, 0),
(6543, '2021-05-18 10:30:00', 0, 0),
(6544, '2021-05-18 10:45:00', 0, 0),
(6545, '2021-05-18 11:00:00', 0, 0),
(6546, '2021-05-18 11:15:00', 0, 0),
(6547, '2021-05-18 11:30:00', 0, 0),
(6548, '2021-05-18 11:45:00', 0, 0),
(6549, '2021-05-18 12:00:00', 0, 0),
(6550, '2021-05-18 14:00:00', 0, 0),
(6551, '2021-05-18 14:15:00', 0, 0),
(6552, '2021-05-18 14:30:00', 0, 0),
(6553, '2021-05-18 14:45:00', 0, 0),
(6554, '2021-05-18 15:00:00', 0, 0),
(6555, '2021-05-18 15:15:00', 0, 0),
(6556, '2021-05-18 15:30:00', 0, 0),
(6557, '2021-05-18 15:45:00', 0, 0),
(6558, '2021-05-18 16:00:00', 0, 0),
(6559, '2021-05-18 16:15:00', 0, 0),
(6560, '2021-05-18 16:30:00', 0, 0),
(6561, '2021-05-18 16:45:00', 0, 0),
(6562, '2021-05-18 17:00:00', 0, 0),
(6563, '2021-05-18 17:15:00', 0, 0),
(6564, '2021-05-18 17:30:00', 0, 0),
(6565, '2021-05-18 17:45:00', 0, 0),
(6566, '2021-05-19 09:00:00', 0, 0),
(6567, '2021-05-19 09:15:00', 0, 0),
(6568, '2021-05-19 09:30:00', 0, 0),
(6569, '2021-05-19 09:45:00', 0, 0),
(6570, '2021-05-19 10:00:00', 0, 0),
(6571, '2021-05-19 10:15:00', 0, 0),
(6572, '2021-05-19 10:30:00', 0, 0),
(6573, '2021-05-19 10:45:00', 0, 0),
(6574, '2021-05-19 11:00:00', 0, 0),
(6575, '2021-05-19 11:15:00', 0, 0),
(6576, '2021-05-19 11:30:00', 0, 0),
(6577, '2021-05-19 11:45:00', 0, 0),
(6578, '2021-05-19 12:00:00', 0, 0),
(6579, '2021-05-19 14:00:00', 0, 0),
(6580, '2021-05-19 14:15:00', 0, 0),
(6581, '2021-05-19 14:30:00', 0, 0),
(6582, '2021-05-19 14:45:00', 0, 0),
(6583, '2021-05-19 15:00:00', 0, 0),
(6584, '2021-05-19 15:15:00', 0, 0),
(6585, '2021-05-19 15:30:00', 0, 0),
(6586, '2021-05-19 15:45:00', 0, 0),
(6587, '2021-05-19 16:00:00', 0, 0),
(6588, '2021-05-19 16:15:00', 0, 0),
(6589, '2021-05-19 16:30:00', 0, 0),
(6590, '2021-05-19 16:45:00', 0, 0),
(6591, '2021-05-19 17:00:00', 0, 0),
(6592, '2021-05-19 17:15:00', 0, 0),
(6593, '2021-05-19 17:30:00', 0, 0),
(6594, '2021-05-19 17:45:00', 0, 0),
(6595, '2021-05-20 09:00:00', 0, 0),
(6596, '2021-05-20 09:15:00', 0, 0),
(6597, '2021-05-20 09:30:00', 0, 0),
(6598, '2021-05-20 09:45:00', 0, 0),
(6599, '2021-05-20 10:00:00', 0, 0),
(6600, '2021-05-20 10:15:00', 0, 0),
(6601, '2021-05-20 10:30:00', 0, 0),
(6602, '2021-05-20 10:45:00', 0, 0),
(6603, '2021-05-20 11:00:00', 0, 0),
(6604, '2021-05-20 11:15:00', 0, 0),
(6605, '2021-05-20 11:30:00', 0, 0),
(6606, '2021-05-20 11:45:00', 0, 0),
(6607, '2021-05-20 12:00:00', 0, 0),
(6608, '2021-05-20 14:00:00', 0, 0),
(6609, '2021-05-20 14:15:00', 0, 0),
(6610, '2021-05-20 14:30:00', 0, 0),
(6611, '2021-05-20 14:45:00', 0, 0),
(6612, '2021-05-20 15:00:00', 0, 0),
(6613, '2021-05-20 15:15:00', 0, 0),
(6614, '2021-05-20 15:30:00', 0, 0),
(6615, '2021-05-20 15:45:00', 0, 0),
(6616, '2021-05-20 16:00:00', 0, 0),
(6617, '2021-05-20 16:15:00', 0, 0),
(6618, '2021-05-20 16:30:00', 0, 0),
(6619, '2021-05-20 16:45:00', 0, 0),
(6620, '2021-05-20 17:00:00', 0, 0),
(6621, '2021-05-20 17:15:00', 0, 0),
(6622, '2021-05-20 17:30:00', 0, 0),
(6623, '2021-05-20 17:45:00', 0, 0),
(6624, '2021-05-21 09:00:00', 0, 0),
(6625, '2021-05-21 09:15:00', 0, 0),
(6626, '2021-05-21 09:30:00', 0, 0),
(6627, '2021-05-21 09:45:00', 0, 0),
(6628, '2021-05-21 10:00:00', 0, 0),
(6629, '2021-05-21 10:15:00', 0, 0),
(6630, '2021-05-21 10:30:00', 0, 0),
(6631, '2021-05-21 10:45:00', 0, 0),
(6632, '2021-05-21 11:00:00', 0, 0),
(6633, '2021-05-21 11:15:00', 0, 0),
(6634, '2021-05-21 11:30:00', 0, 0),
(6635, '2021-05-21 11:45:00', 0, 0),
(6636, '2021-05-21 12:00:00', 0, 0),
(6637, '2021-05-21 14:00:00', 0, 0),
(6638, '2021-05-21 14:15:00', 0, 0),
(6639, '2021-05-21 14:30:00', 0, 0),
(6640, '2021-05-21 14:45:00', 0, 0),
(6641, '2021-05-21 15:00:00', 0, 0),
(6642, '2021-05-21 15:15:00', 0, 0),
(6643, '2021-05-21 15:30:00', 0, 0),
(6644, '2021-05-21 15:45:00', 0, 0),
(6645, '2021-05-21 16:00:00', 0, 0),
(6646, '2021-05-21 16:15:00', 0, 0),
(6647, '2021-05-21 16:30:00', 0, 0),
(6648, '2021-05-21 16:45:00', 0, 0),
(6649, '2021-05-21 17:00:00', 0, 0),
(6650, '2021-05-21 17:15:00', 0, 0),
(6651, '2021-05-21 17:30:00', 0, 0),
(6652, '2021-05-21 17:45:00', 0, 0),
(6653, '2021-05-24 09:00:00', 0, 0),
(6654, '2021-05-24 09:15:00', 0, 0),
(6655, '2021-05-24 09:30:00', 0, 0),
(6656, '2021-05-24 09:45:00', 0, 0),
(6657, '2021-05-24 10:00:00', 0, 0),
(6658, '2021-05-24 10:15:00', 0, 0),
(6659, '2021-05-24 10:30:00', 0, 0),
(6660, '2021-05-24 10:45:00', 0, 0),
(6661, '2021-05-24 11:00:00', 0, 0),
(6662, '2021-05-24 11:15:00', 0, 0),
(6663, '2021-05-24 11:30:00', 0, 0),
(6664, '2021-05-24 11:45:00', 0, 0),
(6665, '2021-05-24 12:00:00', 0, 0),
(6666, '2021-05-24 14:00:00', 0, 0),
(6667, '2021-05-24 14:15:00', 0, 0),
(6668, '2021-05-24 14:30:00', 0, 0),
(6669, '2021-05-24 14:45:00', 0, 0),
(6670, '2021-05-24 15:00:00', 0, 0),
(6671, '2021-05-24 15:15:00', 0, 0),
(6672, '2021-05-24 15:30:00', 0, 0),
(6673, '2021-05-24 15:45:00', 0, 0),
(6674, '2021-05-24 16:00:00', 0, 0),
(6675, '2021-05-24 16:15:00', 0, 0),
(6676, '2021-05-24 16:30:00', 0, 0),
(6677, '2021-05-24 16:45:00', 0, 0),
(6678, '2021-05-24 17:00:00', 0, 0),
(6679, '2021-05-24 17:15:00', 0, 0),
(6680, '2021-05-24 17:30:00', 0, 0),
(6681, '2021-05-24 17:45:00', 0, 0),
(6682, '2021-05-25 09:00:00', 0, 0),
(6683, '2021-05-25 09:15:00', 0, 0),
(6684, '2021-05-25 09:30:00', 0, 0),
(6685, '2021-05-25 09:45:00', 0, 0),
(6686, '2021-05-25 10:00:00', 0, 0),
(6687, '2021-05-25 10:15:00', 0, 0),
(6688, '2021-05-25 10:30:00', 0, 0),
(6689, '2021-05-25 10:45:00', 0, 0),
(6690, '2021-05-25 11:00:00', 0, 0),
(6691, '2021-05-25 11:15:00', 0, 0),
(6692, '2021-05-25 11:30:00', 0, 0),
(6693, '2021-05-25 11:45:00', 0, 0),
(6694, '2021-05-25 12:00:00', 0, 0),
(6695, '2021-05-25 14:00:00', 0, 0),
(6696, '2021-05-25 14:15:00', 0, 0),
(6697, '2021-05-25 14:30:00', 0, 0),
(6698, '2021-05-25 14:45:00', 0, 0),
(6699, '2021-05-25 15:00:00', 0, 0),
(6700, '2021-05-25 15:15:00', 0, 0),
(6701, '2021-05-25 15:30:00', 0, 0),
(6702, '2021-05-25 15:45:00', 0, 0),
(6703, '2021-05-25 16:00:00', 0, 0),
(6704, '2021-05-25 16:15:00', 0, 0),
(6705, '2021-05-25 16:30:00', 0, 0),
(6706, '2021-05-25 16:45:00', 0, 0),
(6707, '2021-05-25 17:00:00', 0, 0),
(6708, '2021-05-25 17:15:00', 0, 0),
(6709, '2021-05-25 17:30:00', 0, 0),
(6710, '2021-05-25 17:45:00', 0, 0),
(6711, '2021-05-26 09:00:00', 0, 0),
(6712, '2021-05-26 09:15:00', 0, 0),
(6713, '2021-05-26 09:30:00', 0, 0),
(6714, '2021-05-26 09:45:00', 0, 0),
(6715, '2021-05-26 10:00:00', 0, 0),
(6716, '2021-05-26 10:15:00', 0, 0),
(6717, '2021-05-26 10:30:00', 0, 0),
(6718, '2021-05-26 10:45:00', 0, 0),
(6719, '2021-05-26 11:00:00', 0, 0),
(6720, '2021-05-26 11:15:00', 0, 0),
(6721, '2021-05-26 11:30:00', 0, 0),
(6722, '2021-05-26 11:45:00', 0, 0),
(6723, '2021-05-26 12:00:00', 0, 0),
(6724, '2021-05-26 14:00:00', 0, 0),
(6725, '2021-05-26 14:15:00', 0, 0),
(6726, '2021-05-26 14:30:00', 0, 0),
(6727, '2021-05-26 14:45:00', 0, 0),
(6728, '2021-05-26 15:00:00', 0, 0),
(6729, '2021-05-26 15:15:00', 0, 0),
(6730, '2021-05-26 15:30:00', 0, 0),
(6731, '2021-05-26 15:45:00', 0, 0),
(6732, '2021-05-26 16:00:00', 0, 0),
(6733, '2021-05-26 16:15:00', 0, 0),
(6734, '2021-05-26 16:30:00', 0, 0),
(6735, '2021-05-26 16:45:00', 0, 0),
(6736, '2021-05-26 17:00:00', 0, 0),
(6737, '2021-05-26 17:15:00', 0, 0),
(6738, '2021-05-26 17:30:00', 0, 0),
(6739, '2021-05-26 17:45:00', 0, 0),
(11815, '2021-05-27 09:00:00', 0, 0),
(11816, '2021-05-27 09:15:00', 0, 0),
(11817, '2021-05-27 09:30:00', 0, 0),
(11818, '2021-05-27 09:45:00', 0, 0),
(11819, '2021-05-27 10:00:00', 0, 0),
(11820, '2021-05-27 10:15:00', 0, 0),
(11821, '2021-05-27 10:30:00', 0, 0),
(11822, '2021-05-27 10:45:00', 0, 0),
(11823, '2021-05-27 11:00:00', 0, 0),
(11824, '2021-05-27 11:15:00', 0, 0),
(11825, '2021-05-27 11:30:00', 0, 0),
(11826, '2021-05-27 11:45:00', 0, 0),
(11827, '2021-05-27 12:00:00', 0, 0),
(11828, '2021-05-27 14:00:00', 0, 0),
(11829, '2021-05-27 14:15:00', 0, 0),
(11830, '2021-05-27 14:30:00', 0, 0),
(11831, '2021-05-27 14:45:00', 0, 0),
(11832, '2021-05-27 15:00:00', 0, 0),
(11833, '2021-05-27 15:15:00', 0, 0),
(11834, '2021-05-27 15:30:00', 0, 0),
(11835, '2021-05-27 15:45:00', 0, 0),
(11836, '2021-05-27 16:00:00', 0, 0),
(11837, '2021-05-27 16:15:00', 0, 0),
(11838, '2021-05-27 16:30:00', 0, 0),
(11839, '2021-05-27 16:45:00', 0, 0),
(11840, '2021-05-27 17:00:00', 0, 0),
(11841, '2021-05-27 17:15:00', 0, 0),
(11842, '2021-05-27 17:30:00', 0, 0),
(11843, '2021-05-27 17:45:00', 0, 0);

-- --------------------------------------------------------

--
-- Structure de la table `user`
--

CREATE TABLE `user` (
  `id` int(11) NOT NULL,
  `name` varchar(60) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Déchargement des données de la table `user`
--

INSERT INTO `user` (`id`, `name`, `email`, `password`) VALUES
(1, 'SMITH Abraham', 'a.smith@email.net', '0000'),
(2, 'DOE John', 'j.doe@email.net', '0000'),
(3, 'STAN Johan', 'j.stan@email.net', '1234');

--
-- Déclencheurs `user`
--
DELIMITER $$
CREATE TRIGGER `insert_user_basket` AFTER INSERT ON `user` FOR EACH ROW BEGIN
INSERT INTO basket(name,idUser) VALUES('Mis de côté',NEW.id);
END
$$
DELIMITER ;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `associatedproduct`
--
ALTER TABLE `associatedproduct`
  ADD PRIMARY KEY (`idProduct`,`idAssoProduct`),
  ADD KEY `productsasso_ibfk_1` (`idAssoProduct`);

--
-- Index pour la table `basket`
--
ALTER TABLE `basket`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idUser` (`idUser`);

--
-- Index pour la table `basketdetail`
--
ALTER TABLE `basketdetail`
  ADD PRIMARY KEY (`idBasket`,`idProduct`),
  ADD KEY `idProduct` (`idProduct`);

--
-- Index pour la table `employee`
--
ALTER TABLE `employee`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `order`
--
ALTER TABLE `order`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idUser` (`idUser`),
  ADD KEY `idEmployee` (`idEmployee`),
  ADD KEY `idTimeslot` (`idTimeslot`);

--
-- Index pour la table `orderdetail`
--
ALTER TABLE `orderdetail`
  ADD PRIMARY KEY (`idOrder`,`idProduct`),
  ADD KEY `idProduct` (`idProduct`);

--
-- Index pour la table `pack`
--
ALTER TABLE `pack`
  ADD PRIMARY KEY (`idProduct`,`idPack`),
  ADD KEY `idProduct` (`idPack`);

--
-- Index pour la table `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idSection` (`idSection`);
ALTER TABLE `product` ADD FULLTEXT KEY `name` (`name`);
ALTER TABLE `product` ADD FULLTEXT KEY `comments` (`comments`);

--
-- Index pour la table `section`
--
ALTER TABLE `section`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `slot`
--
ALTER TABLE `slot`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `timeslot`
--
ALTER TABLE `timeslot`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slotDate` (`slotDate`);

--
-- Index pour la table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `basket`
--
ALTER TABLE `basket`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT pour la table `employee`
--
ALTER TABLE `employee`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pour la table `order`
--
ALTER TABLE `order`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;

--
-- AUTO_INCREMENT pour la table `product`
--
ALTER TABLE `product`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=154;

--
-- AUTO_INCREMENT pour la table `section`
--
ALTER TABLE `section`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=49;

--
-- AUTO_INCREMENT pour la table `slot`
--
ALTER TABLE `slot`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT pour la table `timeslot`
--
ALTER TABLE `timeslot`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32260;

--
-- AUTO_INCREMENT pour la table `user`
--
ALTER TABLE `user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `associatedproduct`
--
ALTER TABLE `associatedproduct`
  ADD CONSTRAINT `associatedproduct_ibfk_1` FOREIGN KEY (`idAssoProduct`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `associatedproduct_ibfk_2` FOREIGN KEY (`idProduct`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `basket`
--
ALTER TABLE `basket`
  ADD CONSTRAINT `basket_ibfk_1` FOREIGN KEY (`idUser`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `basketdetail`
--
ALTER TABLE `basketdetail`
  ADD CONSTRAINT `basketdetail_ibfk_1` FOREIGN KEY (`idBasket`) REFERENCES `basket` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `basketdetail_ibfk_2` FOREIGN KEY (`idProduct`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `order`
--
ALTER TABLE `order`
  ADD CONSTRAINT `order_ibfk_1` FOREIGN KEY (`idUser`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `order_ibfk_2` FOREIGN KEY (`idEmployee`) REFERENCES `employee` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `order_ibfk_3` FOREIGN KEY (`idTimeslot`) REFERENCES `timeslot` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Contraintes pour la table `orderdetail`
--
ALTER TABLE `orderdetail`
  ADD CONSTRAINT `orderdetail_ibfk_1` FOREIGN KEY (`idOrder`) REFERENCES `order` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `orderdetail_ibfk_2` FOREIGN KEY (`idProduct`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `pack`
--
ALTER TABLE `pack`
  ADD CONSTRAINT `pack_ibfk_1` FOREIGN KEY (`idProduct`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `pack_ibfk_2` FOREIGN KEY (`idPack`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Contraintes pour la table `product`
--
ALTER TABLE `product`
  ADD CONSTRAINT `product_ibfk_1` FOREIGN KEY (`idSection`) REFERENCES `section` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
