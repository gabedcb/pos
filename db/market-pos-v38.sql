-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 14-10-2023 a las 22:50:45
-- Versión del servidor: 10.4.28-MariaDB
-- Versión de PHP: 8.0.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `mitiendaposfacturador`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ActualizarDetalleVenta` (IN `p_codigo_producto` VARCHAR(20), IN `p_cantidad` FLOAT, IN `p_id` INT)   BEGIN

 declare v_nro_boleta varchar(20);
 declare v_total_venta float;

/*
ACTUALIZAR EL STOCK DEL PRODUCTO QUE SEA MODIFICADO
......
.....
.......
*/

/*
ACTULIZAR CODIGO, CANTIDAD Y TOTAL DEL ITEM MODIFICADO
*/

 UPDATE venta_detalle 
 SET codigo_producto = p_codigo_producto, 
 cantidad = p_cantidad, 
 total_venta = (p_cantidad * (select precio_venta_producto from productos where codigo_producto = p_codigo_producto))
 WHERE id = p_id;
 
 set v_nro_boleta = (select nro_boleta from venta_detalle where id = p_id);
 set v_total_venta = (select sum(total_venta) from venta_detalle where nro_boleta = v_nro_boleta);
 
 update venta_cabecera
   set total_venta = v_total_venta
 where nro_boleta = v_nro_boleta;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_eliminar_venta` (IN `p_nro_boleta` VARCHAR(8))   BEGIN

DECLARE v_codigo VARCHAR(20);
DECLARE v_cantidad FLOAT;
DECLARE done INT DEFAULT FALSE;

DECLARE cursor_i CURSOR FOR 
SELECT codigo_producto,cantidad 
FROM venta_detalle 
where CAST(nro_boleta AS CHAR CHARACTER SET utf8)  = CAST(p_nro_boleta AS CHAR CHARACTER SET utf8) ;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

OPEN cursor_i;
read_loop: LOOP
FETCH cursor_i INTO v_codigo, v_cantidad;

	IF done THEN
	  LEAVE read_loop;
	END IF;
    
    UPDATE PRODUCTOS 
       SET stock_producto = stock_producto + v_cantidad
    WHERE CAST(codigo_producto AS CHAR CHARACTER SET utf8) = CAST(v_codigo AS CHAR CHARACTER SET utf8);
    
END LOOP;
CLOSE cursor_i;

DELETE FROM VENTA_DETALLE WHERE CAST(nro_boleta AS CHAR CHARACTER SET utf8) = CAST(p_nro_boleta AS CHAR CHARACTER SET utf8) ;
DELETE FROM VENTA_CABECERA WHERE CAST(nro_boleta AS CHAR CHARACTER SET utf8)  = CAST(p_nro_boleta AS CHAR CHARACTER SET utf8) ;

SELECT 'Se eliminó correctamente la venta';
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarCategorias` ()   BEGIN
select * from categorias;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductos` ()   SELECT  '' as detalles,
		'' as acciones,
		codigo_producto,
		p.id_categoria,
        imagen,
		upper(c.descripcion) as nombre_categoria,
		upper(p.descripcion) as producto,
        p.id_tipo_afectacion_igv,
        upper(tai.descripcion) as tipo_afectacion_igv,
        p.id_unidad_medida,
        upper(cum.descripcion) as unidad_medida,
		ROUND(costo_unitario,2) as costo_unitario,
		ROUND(precio_unitario_con_igv,2) as precio_unitario_con_igv,
        ROUND(precio_unitario_sin_igv,2) as precio_unitario_sin_igv,
        ROUND(precio_unitario_mayor_con_igv,2) as precio_unitario_mayor_con_igv,
        ROUND(precio_unitario_mayor_sin_igv,2) as precio_unitario_mayor_sin_igv,
        ROUND(precio_unitario_oferta_con_igv,2) as precio_unitario_oferta_con_igv,
        ROUND(precio_unitario_oferta_sin_igv,2) as precio_unitario_oferta_sin_igv,
		stock,
		minimo_stock,
		ventas,
		ROUND(costo_total,2) as costo_total,
		p.fecha_creacion,
		p.fecha_actualizacion,
        case when p.estado = 1 then 'ACTIVO' else 'INACTIVO' end estado
	FROM productos p INNER JOIN categorias c on p.id_categoria = c.id
					 inner join tipo_afectacion_igv tai on tai.codigo = p.id_tipo_afectacion_igv
					inner join codigo_unidad_medida cum on cum.id = p.id_unidad_medida
    WHERE p.estado in (0,1)
	order by p.codigo_producto desc$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductosMasVendidos` ()  NO SQL BEGIN

select  p.codigo_producto,
		p.descripcion,
        sum(vd.cantidad) as cantidad,
        sum(Round(vd.importe_total,2)) as total_venta
from detalle_venta vd inner join productos p on vd.codigo_producto = p.codigo_producto
group by p.codigo_producto,
		p.descripcion
order by  sum(Round(vd.importe_total,2)) DESC
limit 10;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ListarProductosPocoStock` ()  NO SQL BEGIN
select p.codigo_producto,
		p.descripcion,
        p.stock,
        p.minimo_stock
from productos p
where p.stock <= p.minimo_stock
order by p.stock asc;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_movimentos_arqueo_caja_por_usuario` (`p_id_usuario` INT)   BEGIN

select 
ac.monto_apertura as y,
'MONTO APERTURA' as label,
"#6c757d" as color
from arqueo_caja ac inner join usuarios usu on ac.id_usuario = usu.id_usuario
where ac.id_usuario = p_id_usuario
and date(ac.fecha_apertura) = curdate()
union  
select 
ac.ingresos as y,
'INGRESOS' as label,
"#28a745" as color
from arqueo_caja ac inner join usuarios usu on ac.id_usuario = usu.id_usuario
where ac.id_usuario = p_id_usuario
and date(ac.fecha_apertura) = curdate()
union
select 
ac.devoluciones as y,
'DEVOLUCIONES' as label,
"#ffc107" as color
from arqueo_caja ac inner join usuarios usu on ac.id_usuario = usu.id_usuario
where ac.id_usuario = p_id_usuario
and date(ac.fecha_apertura) = curdate()
union
select 
ac.gastos as y,
'GASTOS' as label,
"#17a2b8" as color
from arqueo_caja ac inner join usuarios usu on ac.id_usuario = usu.id_usuario
where ac.id_usuario = p_id_usuario
and date(ac.fecha_apertura) = curdate();
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerDatosDashboard` ()  NO SQL BEGIN
  DECLARE totalProductos int;
  DECLARE totalCompras float;
  DECLARE totalVentas float;
  DECLARE ganancias float;
  DECLARE productosPocoStock int;
  DECLARE ventasHoy float;

  SET totalProductos = (SELECT
      COUNT(*)
    FROM productos p);
    
  SET totalCompras = (SELECT
      SUM(p.costo_total)
    FROM productos p);  

	SET totalVentas = 0;
  SET totalVentas = (SELECT
      SUM(v.importe_total)
    FROM venta v);

  SET ganancias = 0;
  SET ganancias = (SELECT
      SUM(dv.importe_total) - SUM(dv.cantidad * dv.costo_unitario)
    FROM detalle_venta dv);
    
  SET productosPocoStock = (SELECT
      COUNT(1)
    FROM productos p
    WHERE p.stock <= p.minimo_stock);
    
    SET ventasHoy = 0;
  SET ventasHoy = (SELECT
      SUM(v.importe_total)
    FROM venta v
    WHERE DATE(v.fecha_emision) = CURDATE());

  SELECT
    IFNULL(totalProductos, 0) AS totalProductos,
    IFNULL(CONCAT('S./ ', FORMAT(totalCompras, 2)), 0) AS totalCompras,
    IFNULL(CONCAT('S./ ', FORMAT(totalVentas, 2)), 0) AS totalVentas,
    IFNULL(CONCAT('S./ ', FORMAT(ganancias, 2), ' - ','  % ', FORMAT((ganancias / totalVentas) *100,2)), 0) AS ganancias,
    IFNULL(productosPocoStock, 0) AS productosPocoStock,
    IFNULL(CONCAT('S./ ', FORMAT(ventasHoy, 2)), 0) AS ventasHoy;



END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_obtenerNroBoleta` ()  NO SQL select serie_boleta,
		IFNULL(LPAD(max(c.nro_correlativo_venta)+1,8,'0'),'00000001') nro_venta 
from empresa c$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerVentasMesActual` ()  NO SQL BEGIN
SELECT date(vc.fecha_emision) as fecha_venta,
		sum(round(vc.importe_total,2)) as total_venta,
        ifnull((SELECT sum(round(vc1.importe_total,2))
			FROM venta vc1
		where date(vc1.fecha_emision) >= date(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
		and date(vc1.fecha_emision) <= last_day(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
        and date(vc1.fecha_emision) = DATE_ADD(date(vc.fecha_emision), INTERVAL -1 MONTH)
		group by date(vc1.fecha_emision)),0) as total_venta_ant
FROM venta vc
where date(vc.fecha_emision) >= date(last_day(now() - INTERVAL 1 month) + INTERVAL 1 day)
and date(vc.fecha_emision) <= last_day(date(CURRENT_DATE))
group by date(vc.fecha_emision);


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_ObtenerVentasMesAnterior` ()  NO SQL BEGIN
SELECT date(vc.fecha_venta) as fecha_venta,
		sum(round(vc.total_venta,2)) as total_venta,
        sum(round(vc.total_venta,2)) as total_venta_ant
FROM venta_cabecera vc
where date(vc.fecha_venta) >= date(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
and date(vc.fecha_venta) <= last_day(last_day(now() - INTERVAL 2 month) + INTERVAL 1 day)
group by date(vc.fecha_venta);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_bono` (IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_nuevo_stock` FLOAT)   BEGIN

	/*VARIABLES PARA EXISTENCIAS ACTUALES*/
	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_in float;
	declare v_costo_unitario_in float;    
	declare v_costo_total_in float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM KARDEX K
    WHERE K.CODIGO_PRODUCTO = p_codigo_producto
    ORDER BY ID DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE INGRESO*/
    SET v_unidades_in = p_nuevo_stock - v_unidades_ex;
    SET v_costo_unitario_in = v_costo_unitario_ex;
    SET v_costo_total_in = v_unidades_in * v_costo_unitario_in;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(p_nuevo_stock,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex + v_costo_total_in,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
        
	INSERT INTO KARDEX(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        in_unidades,
                        in_costo_unitario,
                        in_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        '',
                        v_unidades_in,
                        v_costo_unitario_in,
                        v_costo_total_in,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE PRODUCTOS 
	SET stock = v_unidades_ex, 
         costo_unitario = v_costo_unitario_ex,
         costo_total= v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_compra` (IN `p_id_compra` INT, IN `p_comprobante` VARCHAR(20), IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_cantidad_compra` FLOAT, IN `p_costo_compra` FLOAT)   BEGIN

	/*VARIABLES PARA EXISTENCIAS ACTUALES*/
	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_in float;
	declare v_costo_unitario_in float;    
	declare v_costo_total_in float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM KARDEX K
    WHERE K.CODIGO_PRODUCTO = p_codigo_producto
    ORDER BY ID DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE INGRESO*/
    SET v_unidades_in = p_cantidad_compra;
    SET v_costo_unitario_in = p_costo_compra;
    SET v_costo_total_in = v_unidades_in * v_costo_unitario_in;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = v_unidades_ex + ROUND(p_cantidad_compra,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex + v_costo_total_in,2);
    SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);

	INSERT INTO KARDEX(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        in_unidades,
                        in_costo_unitario,
                        in_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        p_comprobante,
                        v_unidades_in,
                        v_costo_unitario_in,
                        v_costo_total_in,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE PRODUCTOS 
	SET stock = v_unidades_ex, 
         costo_unitario = v_costo_unitario_ex,
         costo_total= v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;  
  

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_existencias` (IN `p_codigo_producto` VARCHAR(25), IN `p_concepto` VARCHAR(100), IN `p_comprobante` VARCHAR(100), IN `p_unidades` FLOAT, IN `p_costo_unitario` FLOAT, IN `p_costo_total` FLOAT)   BEGIN
  INSERT INTO KARDEX (codigo_producto, fecha, concepto, comprobante, ex_unidades, ex_costo_unitario, ex_costo_total)
    VALUES (p_codigo_producto, CURDATE(), p_concepto, p_comprobante, p_unidades, p_costo_unitario, p_costo_total);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_vencido` (IN `p_codigo_producto` VARCHAR(20), IN `p_concepto` VARCHAR(100), IN `p_nuevo_stock` FLOAT)   BEGIN

	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_out float;
	declare v_costo_unitario_out float;    
	declare v_costo_total_out float;
    
	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM KARDEX K
    WHERE K.CODIGO_PRODUCTO = p_codigo_producto
    ORDER BY ID DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE SALIDA*/
    SET v_unidades_out = v_unidades_ex - p_nuevo_stock;
    SET v_costo_unitario_out = v_costo_unitario_ex;
    SET v_costo_total_out = v_unidades_out * v_costo_unitario_out;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(p_nuevo_stock,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex - v_costo_total_out,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
        
	INSERT INTO KARDEX(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        out_unidades,
                        out_costo_unitario,
                        out_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						curdate(),
                        p_concepto,
                        '',
                        v_unidades_out,
                        v_costo_unitario_out,
                        v_costo_total_out,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE PRODUCTOS 
	SET stock = v_unidades_ex, 
         costo_unitario = v_costo_unitario_ex,
        costo_total = v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_kardex_venta` (IN `p_codigo_producto` VARCHAR(20), IN `p_fecha` DATE, IN `p_concepto` VARCHAR(100), IN `p_comprobante` VARCHAR(100), IN `p_unidades` FLOAT)   BEGIN

	declare v_unidades_ex float;
	declare v_costo_unitario_ex float;    
	declare v_costo_total_ex float;
    
    declare v_unidades_out float;
	declare v_costo_unitario_out float;    
	declare v_costo_total_out float;
    

	/*OBTENEMOS LAS ULTIMAS EXISTENCIAS DEL PRODUCTO*/
    
    SELECT k.ex_costo_unitario , k.ex_unidades, k.ex_costo_total
    into v_costo_unitario_ex, v_unidades_ex, v_costo_total_ex
    FROM KARDEX K
    WHERE K.CODIGO_PRODUCTO = p_codigo_producto
    ORDER BY ID DESC
    LIMIT 1;
    
    /*SETEAMOS LOS VALORES PARA EL REGISTRO DE SALIDA*/
    SET v_unidades_out = p_unidades;
    SET v_costo_unitario_out = v_costo_unitario_ex;
    SET v_costo_total_out = p_unidades * v_costo_unitario_ex;
    
    /*SETEAMOS LAS EXISTENCIAS ACTUALES*/
    SET v_unidades_ex = ROUND(v_unidades_ex - v_unidades_out,2);    
    SET v_costo_total_ex = ROUND(v_costo_total_ex -  v_costo_total_out,2);
    
    IF(v_costo_total_ex > 0) THEN
		SET v_costo_unitario_ex = ROUND(v_costo_total_ex/v_unidades_ex,2);
	else
		SET v_costo_unitario_ex = ROUND(0,2);
    END IF;
    
        
	INSERT INTO KARDEX(codigo_producto,
						fecha,
                        concepto,
                        comprobante,
                        out_unidades,
                        out_costo_unitario,
                        out_costo_total,
                        ex_unidades,
                        ex_costo_unitario,
                        ex_costo_total)
				VALUES(p_codigo_producto,
						p_fecha,
                        p_concepto,
                        p_comprobante,
                        v_unidades_out,
                        v_costo_unitario_out,
                        v_costo_total_out,
                        v_unidades_ex,
                        v_costo_unitario_ex,
                        v_costo_total_ex);

	/*ACTUALIZAMOS EL STOCK, EL NRO DE VENTAS DEL PRODUCTO*/
	UPDATE PRODUCTOS 
	SET stock = v_unidades_ex, 
		ventas = ventas + v_unidades_out,
        costo_unitario = v_costo_unitario_ex,
        costo_total = v_costo_total_ex
	WHERE codigo_producto = p_codigo_producto ;                      

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_registrar_venta_detalle` (IN `p_nro_boleta` VARCHAR(8), IN `p_codigo_producto` VARCHAR(20), IN `p_cantidad` FLOAT, IN `p_total_venta` FLOAT)   BEGIN
declare v_precio_compra float;
declare v_precio_venta float;

SELECT p.precio_compra_producto,p.precio_venta_producto
into v_precio_compra, v_precio_venta
FROM productos p
WHERE p.codigo_producto  = p_codigo_producto;
    
INSERT INTO venta_detalle(nro_boleta,codigo_producto, cantidad, costo_unitario_venta,precio_unitario_venta,total_venta, fecha_venta) 
VALUES(p_nro_boleta,p_codigo_producto,p_cantidad, v_precio_compra, v_precio_venta,p_total_venta,curdate());
                                                        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_top_ventas_categorias` ()   BEGIN

select cast(sum(vd.importe_total)  AS DECIMAL(8,2)) as y, c.descripcion as label
    from detalle_venta vd inner join productos p on vd.codigo_producto = p.codigo_producto
                        inner join categorias c on c.id = p.id_categoria
    group by c.descripcion
    LIMIT 10;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prc_truncate_all_tables` ()   BEGIN

SET FOREIGN_KEY_CHECKS = 0;

truncate table venta;
truncate table detalle_venta;
truncate table compras;
truncate table detalle_compra;
truncate table kardex;
truncate table categorias;
truncate table tipo_afectacion_igv;
truncate table codigo_unidad_medida;
truncate table productos;

SET FOREIGN_KEY_CHECKS = 1;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `arqueo_caja`
--

CREATE TABLE `arqueo_caja` (
  `id` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `fecha_apertura` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_cierre` datetime DEFAULT NULL,
  `monto_apertura` float NOT NULL,
  `ingresos` float DEFAULT NULL,
  `devoluciones` float DEFAULT NULL,
  `gastos` float DEFAULT NULL,
  `monto_final` float DEFAULT NULL,
  `estado` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `arqueo_caja`
--

INSERT INTO `arqueo_caja` (`id`, `id_usuario`, `fecha_apertura`, `fecha_cierre`, `monto_apertura`, `ingresos`, `devoluciones`, `gastos`, `monto_final`, `estado`) VALUES
(1, 2, '2023-09-17 20:28:00', '2023-09-17 22:07:39', 80, 475.8, NULL, 30, 525.8, 0),
(2, 2, '2023-09-16 22:36:06', '2023-09-16 22:36:06', 80, NULL, NULL, NULL, NULL, 0),
(3, 2, '2023-09-15 22:59:27', '2023-09-15 22:59:32', 80, 0, 0, 0, 80, 0),
(4, 2, '2023-09-18 23:36:20', '2023-09-18 23:37:02', 80, 0, 0, 0, 80, 0),
(5, 2, '2023-09-19 11:25:27', '2023-09-19 11:25:19', 240, 0, 36, 0, 160, 1),
(6, 1, '2023-09-19 20:01:22', '2023-09-19 20:01:16', 240, 0, 9, 0, 231, 1),
(7, 1, '2023-09-20 12:49:33', NULL, 80, NULL, NULL, NULL, 80, 1),
(8, 1, '2023-09-21 21:50:05', '2023-09-21 21:50:00', 160, 0, 0, 0, 80, 1),
(9, 1, '2023-09-24 23:09:59', NULL, 80, NULL, 15, NULL, 65, 1),
(10, 1, '2023-09-26 23:42:17', '2023-09-26 23:42:27', 80, 0, 0, 0, 80, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cajas`
--

CREATE TABLE `cajas` (
  `id` int(11) NOT NULL,
  `nombre_caja` varchar(100) NOT NULL,
  `estado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `cajas`
--

INSERT INTO `cajas` (`id`, `nombre_caja`, `estado`) VALUES
(1, 'Sin Caja', 1),
(2, 'Caja Barrancio Mod 1', 1),
(3, 'Caja Barrancio Mod 2', 1),
(4, 'Caja Barrancio Mod 3', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(150) NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `fecha_actualizacion` timestamp NULL DEFAULT NULL,
  `estado` int(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`id`, `descripcion`, `fecha_creacion`, `fecha_actualizacion`, `estado`) VALUES
(1, 'Frutas', '2023-10-14 23:57:22', NULL, 1),
(2, 'Verduras', '2023-10-14 23:57:22', NULL, 1),
(3, 'Snack', '2023-10-14 23:57:22', NULL, 1),
(4, 'Avena', '2023-10-14 23:57:22', NULL, 1),
(5, 'Energizante', '2023-10-14 23:57:22', NULL, 1),
(6, 'Jugo', '2023-10-14 23:57:22', NULL, 1),
(7, 'Refresco', '2023-10-14 23:57:22', NULL, 1),
(8, 'Mantequilla', '2023-10-14 23:57:22', NULL, 1),
(9, 'Gaseosa', '2023-10-14 23:57:22', NULL, 1),
(10, 'Aceite', '2023-10-14 23:57:22', NULL, 1),
(11, 'Yogurt', '2023-10-14 23:57:22', NULL, 1),
(12, 'Arroz', '2023-10-14 23:57:22', NULL, 1),
(13, 'Leche', '2023-10-14 23:57:22', NULL, 1),
(14, 'Papel Higiénico', '2023-10-14 23:57:22', NULL, 1),
(15, 'Atún', '2023-10-14 23:57:22', NULL, 1),
(16, 'Chocolate', '2023-10-14 23:57:22', NULL, 1),
(17, 'Wafer', '2023-10-14 23:57:22', NULL, 1),
(18, 'Golosina', '2023-10-14 23:57:22', NULL, 1),
(19, 'Galletas', '2023-10-14 23:57:22', NULL, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id` int(11) NOT NULL,
  `id_tipo_documento` int(11) DEFAULT NULL,
  `nro_documento` varchar(20) DEFAULT NULL,
  `nombres_apellidos_razon_social` varchar(255) DEFAULT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`id`, `id_tipo_documento`, `nro_documento`, `nombres_apellidos_razon_social`, `direccion`, `telefono`, `estado`) VALUES
(1, 1, '45257895', 'LUIS ANGEL LOZANO ARICA', 'CALLE BUENAVENTURA AGUIRRE 302', '978451242', 1),
(2, 1, '42584137', 'FIORELLA JESSICA OSORES VALLEJO', 'CALLE FANING 4512', '87845124', 1),
(3, 1, '78926626', 'RAFAEL IGNACIO LOZANO OSORES', 'CALLE ARRIETA 123', '978451223', 1),
(4, 1, '45788956', 'JUAN CARLOS LOZANO ARICA', 'CALLE EL CEREZO 123', '978561245', 0),
(5, 1, '12345678', 'EMILIA SOFIA LOZANO OSORES', 'CALLE ARRIETA 9874', '956231245', 1),
(8, 1, '42584136', 'FIORELLA JESSICA OSORES VALLEJO', 'calle de prueba', '1232132', 1),
(9, 6, '20552103816', 'AGROLIGHT PERU S.A.C.', 'PJ. JORGE BASADRE NRO 158 URB. POP LA UNIVERSAL 2DA ET. ', '97845212', 1),
(10, 0, '99999999', 'CLIENTES VARIOS', '-', '-', 1),
(11, 6, '20480316259', 'D\'AROMAS E.I.R.L.', 'MZA. J LOTE 05 URB. EL JOCKEY ', '987354321', 1),
(12, 6, '20538856674', 'ARTROSCOPICTRAUMA S.A.C.', 'AV. GRAL.GARZON NRO 2320 URB. FUNDO OYAGUE ', '', 1),
(13, 6, '20603033176', '360 SISTEMAS GERENCIALES S.A.C.', 'CAL. PORTA NRO 170 INT. 512 COM. SAN MIGUEL DE MIRAFLORES ', '', 1),
(14, 6, '20605967800', '360 ECOMMERCE SOLUTIONS S.A.C.', 'CAL. CLEMENTE X NRO 182 URB. SAN FELIPE ', '', 1),
(15, 6, '20604915351', 'EMPRESA COMPRADORA', 'AVENIDA LIMA 123', '', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `codigo_unidad_medida`
--

CREATE TABLE `codigo_unidad_medida` (
  `id` varchar(3) NOT NULL,
  `descripcion` varchar(150) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `codigo_unidad_medida`
--

INSERT INTO `codigo_unidad_medida` (`id`, `descripcion`, `estado`) VALUES
('BO', 'BOTELLAS', 1),
('BX', 'CAJA', 1),
('DZN', 'DOCENA', 1),
('KGM', 'KILOGRAMO', 1),
('LTR', 'LITRO', 1),
('MIL', 'MILLARES', 1),
('NIU', 'UNIDAD', 1),
('PK', 'PAQUETE', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `compras`
--

CREATE TABLE `compras` (
  `id` int(11) NOT NULL,
  `id_proveedor` int(11) DEFAULT NULL,
  `fecha_compra` datetime DEFAULT NULL,
  `id_tipo_comprobante` varchar(3) DEFAULT NULL,
  `serie` varchar(10) DEFAULT NULL,
  `correlativo` varchar(20) DEFAULT NULL,
  `id_moneda` varchar(3) DEFAULT NULL,
  `ope_exonerada` float DEFAULT NULL,
  `ope_inafecta` float DEFAULT NULL,
  `ope_gravada` float DEFAULT NULL,
  `total_igv` float DEFAULT NULL,
  `descuento` float DEFAULT NULL,
  `total_compra` float DEFAULT NULL,
  `estado` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `compras`
--

INSERT INTO `compras` (`id`, `id_proveedor`, `fecha_compra`, `id_tipo_comprobante`, `serie`, `correlativo`, `id_moneda`, `ope_exonerada`, `ope_inafecta`, `ope_gravada`, `total_igv`, `descuento`, `total_compra`, `estado`) VALUES
(1, 2, '2023-10-14 00:00:00', '01', 'F001', '123', 'PEN', 0, 0, 91.36, 16.44, 0, 107.8, 2),
(2, 2, '2023-10-14 00:00:00', '01', 'F234', '234', 'PEN', 0, 0, 445.5, 80.19, 0, 525.69, 1),
(3, 2, '2023-10-14 00:00:00', '03', 'B123', '123', 'PEN', 0, 0, 354.92, 63.88, 0, 418.8, 1),
(4, 1, '2023-10-14 00:00:00', '03', 'B124', '456', 'PEN', 0, 0, 647.29, 116.51, 15, 748.8, 2),
(5, 1, '2023-10-14 00:00:00', '03', 'B112', '1254', 'PEN', 0, 0, 48.77, 8.78, 5, 52.55, 1),
(6, 2, '2023-10-14 00:00:00', '03', 'B001', '1598', 'PEN', 0, 0, 210.17, 37.83, 0, 248, 2),
(7, 1, '2023-10-14 00:00:00', '01', 'F001', '321', 'PEN', 0, 0, 318.9, 57.4, 8, 368.3, 2),
(8, 2, '2023-10-12 00:00:00', '01', 'F001', '1234', 'PEN', 0, 0, 115.53, 20.79, 15, 121.32, 2),
(9, 2, '2023-10-12 00:00:00', '03', 'B001', '321654', 'PEN', 0, 0, 448.25, 80.69, 10, 518.94, 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_compra`
--

CREATE TABLE `detalle_compra` (
  `id` int(11) NOT NULL,
  `id_compra` int(11) DEFAULT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `cantidad` float DEFAULT NULL,
  `costo_unitario` float DEFAULT NULL,
  `descuento` float DEFAULT NULL,
  `subtotal` float DEFAULT NULL,
  `impuesto` float DEFAULT NULL,
  `total` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `detalle_compra`
--

INSERT INTO `detalle_compra` (`id`, `id_compra`, `codigo_producto`, `cantidad`, `costo_unitario`, `descuento`, `subtotal`, `impuesto`, `total`) VALUES
(1, 1, '7755139002902', 11, 9.8, 0, 91.36, 16.44, 107.8),
(2, 2, '7755139002904', 5, 12.4, 0, 52.54, 9.46, 62),
(3, 2, '7755139002903', 6, 12.1, 0, 61.53, 11.07, 72.6),
(4, 2, '7755139002902', 7, 9.8, 0, 58.14, 10.46, 68.6),
(5, 2, '7755139002901', 8, 10, 0, 67.8, 12.2, 80),
(6, 2, '7755139002900', 9, 8.9, 0, 67.88, 12.22, 80.1),
(7, 2, '7755139002899', 10, 8, 0, 67.8, 12.2, 80),
(8, 2, '7755139002898', 11, 7.49, 0, 69.82, 12.57, 82.39),
(9, 3, '7755139002902', 10, 9.8, 0, 83.05, 14.95, 98),
(10, 3, '7755139002901', 11, 10, 0, 93.22, 16.78, 110),
(11, 3, '7755139002900', 12, 8.9, 0, 90.51, 16.29, 106.8),
(12, 3, '7755139002899', 13, 8, 0, 88.14, 15.86, 104),
(13, 4, '7755139002904', 5, 12.4, 15, 52.54, 9.46, 47),
(14, 4, '7755139002903', 6, 12.1, 0, 61.53, 11.07, 72.6),
(15, 4, '7755139002902', 7, 9.8, 0, 58.14, 10.46, 68.6),
(16, 4, '7755139002901', 8, 10, 0, 67.8, 12.2, 80),
(17, 4, '7755139002900', 9, 8.9, 0, 67.88, 12.22, 80.1),
(18, 4, '7755139002899', 10, 8, 0, 67.8, 12.2, 80),
(19, 4, '7755139002898', 11, 7.49, 0, 69.82, 12.57, 82.39),
(20, 4, '7755139002896', 12, 5.9, 0, 60, 10.8, 70.8),
(21, 4, '7755139002895', 13, 5.9, 0, 65, 11.7, 76.7),
(22, 4, '7755139002897', 17, 5.33, 0, 76.79, 13.82, 90.61),
(23, 5, '7755139002901', 1, 10, 0, 8.47, 1.53, 10),
(24, 5, '7755139002861', 2, 2.19, 0, 3.71, 0.67, 4.38),
(25, 5, '7755139002848', 3, 1.9, 0, 4.83, 0.87, 5.7),
(26, 5, '7755139002810', 4, 3.79, 0, 12.85, 2.31, 15.16),
(27, 5, '7755139002811', 5, 3.4, 5, 14.41, 2.59, 12),
(28, 5, '7755139002812', 6, 0.5, 0, 2.54, 0.46, 3),
(29, 5, '7755139002813', 7, 0.33, 0, 1.96, 0.35, 2.31),
(31, 6, '7755139002904', 20, 12.4, 0, 210.17, 37.83, 248),
(32, 7, '7755139002904', 5, 15, 8, 63.56, 11.44, 67),
(33, 7, '7755139002903', 6, 12.1, 0, 61.53, 11.07, 72.6),
(34, 7, '7755139002902', 7, 9.8, 0, 58.14, 10.46, 68.6),
(35, 7, '7755139002901', 8, 10, 0, 67.8, 12.2, 80),
(36, 7, '7755139002900', 9, 8.9, 0, 67.88, 12.22, 80.1),
(42, 8, '7755139002904', 5, 15, 15, 63.56, 11.44, 60),
(43, 8, '7755139002902', 1, 9.8, 0, 8.31, 1.49, 9.8),
(44, 8, '7755139002901', 1, 10, 0, 8.47, 1.53, 10),
(45, 8, '7755139002900', 1, 8.9, 0, 7.54, 1.36, 8.9),
(46, 8, '7755139002899', 1, 8, 0, 6.78, 1.22, 8),
(47, 8, '7755139002898', 1, 7.49, 0, 6.35, 1.14, 7.49),
(48, 8, '7755139002897', 1, 5.33, 0, 4.52, 0.81, 5.33),
(49, 8, '7755139002896', 1, 5.9, 0, 5, 0.9, 5.9),
(50, 8, '7755139002895', 1, 5.9, 0, 5, 0.9, 5.9),
(51, 9, '7755139002904', 5, 13.05, 10, 55.3, 9.95, 55.25),
(52, 9, '7755139002903', 6, 12.1, 0, 61.53, 11.07, 72.6),
(53, 9, '7755139002902', 7, 9.8, 0, 58.14, 10.46, 68.6),
(54, 9, '7755139002901', 8, 10, 0, 67.8, 12.2, 80),
(55, 9, '7755139002900', 9, 8.9, 0, 67.88, 12.22, 80.1),
(56, 9, '7755139002899', 10, 8, 0, 67.8, 12.2, 80),
(57, 9, '7755139002898', 11, 7.49, 0, 69.82, 12.57, 82.39);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_venta`
--

CREATE TABLE `detalle_venta` (
  `id` int(11) NOT NULL,
  `id_venta` int(11) DEFAULT NULL,
  `item` int(11) DEFAULT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `porcentaje_igv` float DEFAULT NULL,
  `cantidad` float DEFAULT NULL,
  `costo_unitario` float DEFAULT NULL,
  `valor_unitario` float DEFAULT NULL,
  `precio_unitario` float DEFAULT NULL,
  `valor_total` float DEFAULT NULL,
  `igv` float DEFAULT NULL,
  `importe_total` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalle_venta`
--

INSERT INTO `detalle_venta` (`id`, `id_venta`, `item`, `codigo_producto`, `descripcion`, `porcentaje_igv`, `cantidad`, `costo_unitario`, `valor_unitario`, `precio_unitario`, `valor_total`, `igv`, `importe_total`) VALUES
(1, 1, 1, '7755139002904', 'Cocinero 1L', 18, 24, 12.4, 13.14, 15.5052, 315.36, 56.7648, 372.125);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empresas`
--

CREATE TABLE `empresas` (
  `id_empresa` int(11) NOT NULL,
  `razon_social` text NOT NULL,
  `nombre_comercial` varchar(255) DEFAULT NULL,
  `id_tipo_documento` varchar(20) DEFAULT NULL,
  `ruc` bigint(20) NOT NULL,
  `direccion` text NOT NULL,
  `simbolo_moneda` varchar(5) DEFAULT NULL,
  `email` text NOT NULL,
  `telefono` varchar(100) DEFAULT NULL,
  `provincia` varchar(100) DEFAULT NULL,
  `departamento` varchar(100) DEFAULT NULL,
  `distrito` varchar(100) DEFAULT NULL,
  `ubigeo` varchar(6) DEFAULT NULL,
  `usuario_sol` varchar(45) DEFAULT NULL,
  `clave_sol` varchar(45) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `empresas`
--

INSERT INTO `empresas` (`id_empresa`, `razon_social`, `nombre_comercial`, `id_tipo_documento`, `ruc`, `direccion`, `simbolo_moneda`, `email`, `telefono`, `provincia`, `departamento`, `distrito`, `ubigeo`, `usuario_sol`, `clave_sol`, `estado`) VALUES
(1, '3D INVERSIONES Y SERVICIOS GENERALES E.I.R.L.	', '3D INVERSIONES Y SERVICIOS GENERALES E.I.R.L.	', '6', 10467291241, 'CALLE BUENAVENTURA AGUIRRE 302 ', 'S/ ', 'cfredes@innred.cl', '+56983851526 - +56999688639', 'LIMA', 'LIMA', 'BARRANCO', '150104', 'MODDATOS', 'MODDATOS', 1),
(2, 'NEGOCIOS WAIMAKU \" E.I.R.L', 'NEGOCIOS WAIMAKU \" E.I.R.L', '6', 20480674414, 'AV GRAU 123', 'S/', 'audio@gmail.com', '987654321', 'LIMA', 'LIMA', 'BARRANCO', '787878', 'moddatos', 'moddatos', 1),
(3, 'IMPORTACIONES FVC EIRL', 'IMPORTACIONES FVC EIRL', '6', 20494099153, 'CALLE LIMA 123', 'S/', 'empresa@gmail.com', '987654321', 'LIMA', 'LIMA', 'JESUS MARIA', '124545', 'moddatos', 'moddatos', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `forma_pago`
--

CREATE TABLE `forma_pago` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(100) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `forma_pago`
--

INSERT INTO `forma_pago` (`id`, `descripcion`, `estado`) VALUES
(1, 'Contado', 1),
(2, 'Crédito', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `impuestos`
--

CREATE TABLE `impuestos` (
  `id_tipo_operacion` int(11) NOT NULL,
  `impuesto` float DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `impuestos`
--

INSERT INTO `impuestos` (`id_tipo_operacion`, `impuesto`, `estado`) VALUES
(10, 18, 1),
(20, 0, 1),
(30, 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `kardex`
--

CREATE TABLE `kardex` (
  `id` int(11) NOT NULL,
  `codigo_producto` varchar(20) DEFAULT NULL,
  `fecha` datetime DEFAULT NULL,
  `concepto` varchar(100) DEFAULT NULL,
  `comprobante` varchar(50) DEFAULT NULL,
  `in_unidades` float DEFAULT NULL,
  `in_costo_unitario` float DEFAULT NULL,
  `in_costo_total` float DEFAULT NULL,
  `out_unidades` float DEFAULT NULL,
  `out_costo_unitario` float DEFAULT NULL,
  `out_costo_total` float DEFAULT NULL,
  `ex_unidades` float DEFAULT NULL,
  `ex_costo_unitario` float DEFAULT NULL,
  `ex_costo_total` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `kardex`
--

INSERT INTO `kardex` (`id`, `codigo_producto`, `fecha`, `concepto`, `comprobante`, `in_unidades`, `in_costo_unitario`, `in_costo_total`, `out_unidades`, `out_costo_unitario`, `out_costo_total`, `ex_unidades`, `ex_costo_unitario`, `ex_costo_total`) VALUES
(1, '7755139002890', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 5.9, 141.6),
(2, '7755139002903', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 12.1, 278.3),
(3, '7755139002904', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 12.4, 359.6),
(4, '7755139002870', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 3.25, 84.5),
(5, '7755139002880', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 5.15, 118.45),
(6, '7755139002902', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 9.8, 284.2),
(7, '7755139002898', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 7.49, 202.23),
(8, '7755139002899', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 8, 208),
(9, '7755139002901', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 10, 260),
(10, '7755139002810', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 3.79, 79.59),
(11, '7755139002878', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 3.99, 99.75),
(12, '7755139002838', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 1.29, 34.83),
(13, '7755139002839', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 1, 27),
(14, '7755139002848', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 1.9, 47.5),
(15, '7755139002863', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 2.8, 75.6),
(16, '7755139002864', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 4.4, 88),
(17, '7755139002865', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 3.79, 87.17),
(18, '7755139002866', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 3.79, 98.54),
(19, '7755139002867', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 3.65, 87.6),
(20, '7755139002868', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 3.5, 70),
(21, '7755139002871', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 3.17, 85.59),
(22, '7755139002877', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 30, 5.17, 155.1),
(23, '7755139002879', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 4.58, 128.24),
(24, '7755139002881', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 5, 110),
(25, '7755139002882', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 4.66, 125.82),
(26, '7755139002883', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 4.65, 106.95),
(27, '7755139002884', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 4.63, 97.23),
(28, '7755139002885', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 5.7, 153.9),
(29, '7755139002887', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 6.08, 164.16),
(30, '7755139002888', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 5.9, 129.8),
(31, '7755139002889', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 5.9, 165.2),
(32, '7755139002891', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 5.9, 171.1),
(33, '7755139002892', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 5.08, 106.68),
(34, '7755139002893', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 5.63, 163.27),
(35, '7755139002895', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 5.9, 171.1),
(36, '7755139002896', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 5.9, 159.3),
(37, '7755139002897', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 5.33, 117.26),
(38, '7755139002900', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 8.9, 186.9),
(39, '7755139002886', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 5.7, 119.7),
(40, '7755139002809', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 18.29, 384.09),
(41, '7755139002874', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 2.8, 78.4),
(42, '7755139002830', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 1, 20),
(43, '7755139002869', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 3.25, 68.25),
(44, '7755139002872', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 30, 3.1, 93),
(45, '7755139002876', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 3.39, 71.19),
(46, '7755139002852', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 1.3, 26),
(47, '7755139002853', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 1.99, 55.72),
(48, '7755139002840', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 1, 29),
(49, '7755139002894', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 5.4, 124.2),
(50, '7755139002814', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 0.53, 13.25),
(51, '7755139002831', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 0.9, 20.7),
(52, '7755139002832', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 0.9, 22.5),
(53, '7755139002835', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 30, 0.67, 20.1),
(54, '7755139002846', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 1.39, 30.58),
(55, '7755139002847', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 30, 1.39, 41.7),
(56, '7755139002850', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 1.39, 29.19),
(57, '7755139002851', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 1.39, 34.75),
(58, '7755139002854', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 2.8, 58.8),
(59, '7755139002855', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 2.6, 57.2),
(60, '7755139002856', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 2.6, 62.4),
(61, '7755139002857', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 2.19, 52.56),
(62, '7755139002861', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 2.19, 61.32),
(63, '7755139002811', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 3.4, 85),
(64, '7755139002812', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 0.5, 14),
(65, '7755139002833', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 0.88, 21.12),
(66, '7755139002837', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 1.5, 36),
(67, '7755139002815', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 0.37, 10.73),
(68, '7755139002817', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 0.68, 14.28),
(69, '7755139002822', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 0.52, 12.48),
(70, '7755139002823', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 0.52, 10.4),
(71, '7755139002824', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 0.52, 11.96),
(72, '7755139002826', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 0.47, 12.69),
(73, '7755139002827', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 0.47, 11.28),
(74, '7755139002828', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 0.47, 13.63),
(75, '7755139002842', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 0.9, 26.1),
(76, '7755139002818', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 24, 0.62, 14.88),
(77, '7755139002836', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 0.56, 12.32),
(78, '7755139002825', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 0.5, 12.5),
(79, '7755139002849', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 1.8, 50.4),
(80, '7755139002875', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 3.69, 81.18),
(81, '7755139002860', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 27, 2.8, 75.6),
(82, '7755139002813', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 0.33, 7.26),
(83, '7755139002816', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 20, 0.43, 8.6),
(84, '7755139002829', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 29, 0.75, 21.75),
(85, '7755139002819', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 28, 0.6, 16.8),
(86, '7755139002834', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 0.85, 17.85),
(87, '7755139002841', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 0.92, 23.92),
(88, '7755139002843', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 1.06, 24.38),
(89, '7755139002844', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 1.5, 39),
(90, '7755139002845', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 1.5, 31.5),
(91, '7755139002858', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 23, 2.6, 59.8),
(92, '7755139002859', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 3, 63),
(93, '7755139002862', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 26, 3.2, 83.2),
(94, '7755139002873', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 25, 2.89, 72.25),
(95, '7755139002820', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 21, 0.57, 11.97),
(96, '7755139002821', '2023-10-14 00:00:00', 'INVENTARIO INICIAL', '', NULL, NULL, NULL, NULL, NULL, NULL, 22, 0.53, 11.66),
(97, '7755139002902', '2023-10-14 00:00:00', 'COMPRA', 'F001-123', 11, 9.8, 107.8, NULL, NULL, NULL, 40, 9.8, 392),
(98, '7755139002904', '2023-10-14 00:00:00', 'COMPRA', 'B124-456', 5, 12.4, 62, NULL, NULL, NULL, 34, 12.4, 421.6),
(99, '7755139002903', '2023-10-14 00:00:00', 'COMPRA', 'B124-456', 6, 12.1, 72.6, NULL, NULL, NULL, 29, 12.1, 350.9),
(100, '7755139002902', '2023-10-14 00:00:00', 'COMPRA', 'B124-456', 7, 9.8, 68.6, NULL, NULL, NULL, 47, 9.8, 460.6),
(101, '7755139002901', '2023-10-14 00:00:00', 'COMPRA', 'B124-456', 8, 10, 80, NULL, NULL, NULL, 34, 10, 340),
(102, '7755139002900', '2023-10-14 00:00:00', 'COMPRA', 'B124-456', 9, 8.9, 80.1, NULL, NULL, NULL, 30, 8.9, 267),
(103, '7755139002899', '2023-10-14 00:00:00', 'COMPRA', 'B124-456', 10, 8, 80, NULL, NULL, NULL, 36, 8, 288),
(104, '7755139002898', '2023-10-14 00:00:00', 'COMPRA', 'B124-456', 11, 7.49, 82.39, NULL, NULL, NULL, 38, 7.49, 284.62),
(105, '7755139002896', '2023-10-14 00:00:00', 'COMPRA', 'B124-456', 12, 5.9, 70.8, NULL, NULL, NULL, 39, 5.9, 230.1),
(106, '7755139002895', '2023-10-14 00:00:00', 'COMPRA', 'B124-456', 13, 5.9, 76.7, NULL, NULL, NULL, 42, 5.9, 247.8),
(107, '7755139002897', '2023-10-14 00:00:00', 'COMPRA', 'B124-456', 17, 5.33, 90.61, NULL, NULL, NULL, 39, 5.33, 207.87),
(108, '7755139002904', '2023-10-14 00:00:00', 'VENTA', 'B001-175', NULL, NULL, NULL, 24, 12.4, 297.6, 10, 12.4, 124),
(109, '7755139002904', '2023-10-14 00:00:00', 'COMPRA', 'B001-1598', 20, 12.4, 248, NULL, NULL, NULL, 30, 12.4, 372),
(110, '7755139002904', '2023-10-14 00:00:00', 'COMPRA', 'F001-321', 5, 15, 75, NULL, NULL, NULL, 35, 12.77, 447),
(111, '7755139002903', '2023-10-14 00:00:00', 'COMPRA', 'F001-321', 6, 12.1, 72.6, NULL, NULL, NULL, 35, 12.1, 423.5),
(112, '7755139002902', '2023-10-14 00:00:00', 'COMPRA', 'F001-321', 7, 9.8, 68.6, NULL, NULL, NULL, 54, 9.8, 529.2),
(113, '7755139002901', '2023-10-14 00:00:00', 'COMPRA', 'F001-321', 8, 10, 80, NULL, NULL, NULL, 42, 10, 420),
(114, '7755139002900', '2023-10-14 00:00:00', 'COMPRA', 'F001-321', 9, 8.9, 80.1, NULL, NULL, NULL, 39, 8.9, 347.1),
(115, '7755139002904', '2023-10-14 00:00:00', 'COMPRA', 'F001-1234', 5, 15, 75, NULL, NULL, NULL, 40, 13.05, 522),
(116, '7755139002902', '2023-10-14 00:00:00', 'COMPRA', 'F001-1234', 1, 9.8, 9.8, NULL, NULL, NULL, 55, 9.8, 539),
(117, '7755139002901', '2023-10-14 00:00:00', 'COMPRA', 'F001-1234', 1, 10, 10, NULL, NULL, NULL, 43, 10, 430),
(118, '7755139002900', '2023-10-14 00:00:00', 'COMPRA', 'F001-1234', 1, 8.9, 8.9, NULL, NULL, NULL, 40, 8.9, 356),
(119, '7755139002899', '2023-10-14 00:00:00', 'COMPRA', 'F001-1234', 1, 8, 8, NULL, NULL, NULL, 37, 8, 296),
(120, '7755139002898', '2023-10-14 00:00:00', 'COMPRA', 'F001-1234', 1, 7.49, 7.49, NULL, NULL, NULL, 39, 7.49, 292.11),
(121, '7755139002897', '2023-10-14 00:00:00', 'COMPRA', 'F001-1234', 1, 5.33, 5.33, NULL, NULL, NULL, 40, 5.33, 213.2),
(122, '7755139002896', '2023-10-14 00:00:00', 'COMPRA', 'F001-1234', 1, 5.9, 5.9, NULL, NULL, NULL, 40, 5.9, 236),
(123, '7755139002895', '2023-10-14 00:00:00', 'COMPRA', 'F001-1234', 1, 5.9, 5.9, NULL, NULL, NULL, 43, 5.9, 253.7),
(124, '7755139002904', '2023-10-14 00:00:00', 'COMPRA', 'B001-321654', 5, 13.05, 65.25, NULL, NULL, NULL, 45, 13.05, 587.25),
(125, '7755139002903', '2023-10-14 00:00:00', 'COMPRA', 'B001-321654', 6, 12.1, 72.6, NULL, NULL, NULL, 41, 12.1, 496.1),
(126, '7755139002902', '2023-10-14 00:00:00', 'COMPRA', 'B001-321654', 7, 9.8, 68.6, NULL, NULL, NULL, 62, 9.8, 607.6),
(127, '7755139002901', '2023-10-14 00:00:00', 'COMPRA', 'B001-321654', 8, 10, 80, NULL, NULL, NULL, 51, 10, 510),
(128, '7755139002900', '2023-10-14 00:00:00', 'COMPRA', 'B001-321654', 9, 8.9, 80.1, NULL, NULL, NULL, 49, 8.9, 436.1),
(129, '7755139002899', '2023-10-14 00:00:00', 'COMPRA', 'B001-321654', 10, 8, 80, NULL, NULL, NULL, 47, 8, 376),
(130, '7755139002898', '2023-10-14 00:00:00', 'COMPRA', 'B001-321654', 11, 7.49, 82.39, NULL, NULL, NULL, 50, 7.49, 374.5);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modulos`
--

CREATE TABLE `modulos` (
  `id` int(11) NOT NULL,
  `modulo` varchar(45) DEFAULT NULL,
  `padre_id` int(11) DEFAULT NULL,
  `vista` varchar(45) DEFAULT NULL,
  `icon_menu` varchar(45) DEFAULT NULL,
  `orden` int(11) DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT NULL,
  `fecha_actualizacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `modulos`
--

INSERT INTO `modulos` (`id`, `modulo`, `padre_id`, `vista`, `icon_menu`, `orden`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(1, 'Tablero Principal', 0, 'dashboard.php', 'fas fa-tachometer-alt', 0, NULL, NULL),
(2, 'Comprobantes', 0, '', 'fas fa-file-invoice-dollar', 1, NULL, NULL),
(3, 'Punto de Venta', 2, 'ventas.php', 'far fa-circle', 6, NULL, NULL),
(4, 'Administrar Ventas', 2, 'administrar_ventas.php', 'far fa-circle', 7, NULL, NULL),
(5, 'Productos', 0, NULL, 'fas fa-cart-plus', 8, NULL, NULL),
(6, 'Inventario', 5, 'productos.php', 'far fa-circle', 9, NULL, NULL),
(7, 'Carga Masiva', 5, 'carga_masiva_productos.php', 'far fa-circle', 10, NULL, NULL),
(8, 'Categorías', 5, 'categorias.php', 'far fa-circle', 11, NULL, NULL),
(9, 'Compras', 0, 'compras.php', 'fas fa-dolly', 13, NULL, NULL),
(10, 'Reportes', 11, 'reportes.php', 'far fa-circle', 15, NULL, NULL),
(11, 'Administracion', 0, NULL, 'fas fa-cogs', 14, NULL, NULL),
(13, 'Módulos / Perfiles', 31, 'seguridad_modulos_perfiles.php', 'far fa-circle', 26, NULL, NULL),
(15, 'Caja', 0, 'caja.php', 'fas fa-cash-register', 12, '2022-12-05 14:44:08', NULL),
(22, 'Tipo Afectación', 11, 'administrar_tipo_afectacion.php', 'far fa-circle', 21, '2023-09-22 05:46:29', NULL),
(23, 'Tipo Comprobante', 11, 'administrar_tipo_comprobante.php', 'far fa-circle', 20, '2023-09-22 05:50:12', NULL),
(24, 'Series', 11, 'administrar_series.php', 'far fa-circle', 22, '2023-09-22 06:15:56', NULL),
(25, 'Clientes', 11, 'administrar_clientes.php', 'far fa-circle', 17, '2023-09-22 06:19:20', NULL),
(26, 'Proveedores', 11, 'administrar_proveedores.php', 'far fa-circle', 18, '2023-09-22 06:19:31', NULL),
(27, 'Empresa', 11, 'administrar_empresas.php', 'far fa-circle', 16, '2023-09-22 06:20:56', NULL),
(28, 'Emitir Boleta', 2, 'venta_boleta.php', 'far fa-circle', 2, '2023-09-26 15:46:51', NULL),
(29, 'Emitir Factura', 2, 'venta_factura.php', 'far fa-circle', 3, '2023-09-26 15:47:09', NULL),
(30, 'Resumen de Boletas', 2, 'venta_resumen_boletas.php', 'far fa-circle', 4, '2023-09-26 15:47:39', NULL),
(31, 'Seguridad', 0, '', 'fas fa-user-shield', 23, '2023-09-26 21:03:11', NULL),
(33, 'Perfiles', 31, 'seguridad_perfiles.php', 'far fa-circle', 24, '2023-09-26 21:04:53', NULL),
(34, 'Usuarios', 31, 'seguridad_usuarios.php', 'far fa-circle', 25, '2023-09-26 21:05:08', NULL),
(37, 'Tipo Documento', 11, 'administrar_tipo_documento.php', 'far fa-circle', 19, '2023-09-30 04:07:02', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `moneda`
--

CREATE TABLE `moneda` (
  `id` char(3) NOT NULL,
  `descripcion` varchar(45) NOT NULL,
  `simbolo` char(5) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `moneda`
--

INSERT INTO `moneda` (`id`, `descripcion`, `simbolo`, `estado`) VALUES
('PEN', 'SOLES', 'S/', 1),
('USD', 'DOLARES', '$', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `movimientos_arqueo_caja`
--

CREATE TABLE `movimientos_arqueo_caja` (
  `id` int(11) NOT NULL,
  `id_arqueo_caja` int(11) DEFAULT NULL,
  `id_tipo_movimiento` int(11) DEFAULT NULL,
  `descripcion` varchar(250) DEFAULT NULL,
  `monto` float DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `movimientos_arqueo_caja`
--

INSERT INTO `movimientos_arqueo_caja` (`id`, `id_arqueo_caja`, `id_tipo_movimiento`, `descripcion`, `monto`, `estado`) VALUES
(1, 5, 1, 'Producto ', 6, 1),
(11, 5, 1, 'Almuerzo', 15, 1),
(12, 5, 1, 'Producto Malogrado', 15, 1),
(13, 6, 1, 'Prueba Devolcuion', 5, 1),
(14, 6, 1, 'Prueba Devolucion 2', 3, 1),
(15, 6, 1, 'Prueba Devolucion 3', 1, 1),
(16, 9, 1, 'Dev. Prueba', 15, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfiles`
--

CREATE TABLE `perfiles` (
  `id_perfil` int(11) NOT NULL,
  `descripcion` varchar(45) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL,
  `fecha_creacion` timestamp NULL DEFAULT NULL,
  `fecha_actualizacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `perfiles`
--

INSERT INTO `perfiles` (`id_perfil`, `descripcion`, `estado`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(1, 'ADMINISTRADOR 1', 1, NULL, NULL),
(2, 'VENDEDOR', 1, NULL, NULL),
(3, 'MESERO', 0, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `perfil_modulo`
--

CREATE TABLE `perfil_modulo` (
  `idperfil_modulo` int(11) NOT NULL,
  `id_perfil` int(11) DEFAULT NULL,
  `id_modulo` int(11) DEFAULT NULL,
  `vista_inicio` tinyint(4) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `perfil_modulo`
--

INSERT INTO `perfil_modulo` (`idperfil_modulo`, `id_perfil`, `id_modulo`, `vista_inicio`, `estado`) VALUES
(13, 1, 13, 0, 1),
(624, 2, 15, 0, 1),
(625, 2, 28, 1, 1),
(626, 2, 2, 0, 1),
(627, 2, 29, 0, 1),
(628, 2, 25, 0, 1),
(629, 2, 11, 0, 1),
(630, 1, 1, 0, 1),
(631, 1, 28, 0, 1),
(632, 1, 2, 0, 1),
(633, 1, 29, 0, 1),
(634, 1, 30, 0, 1),
(635, 1, 6, 0, 1),
(636, 1, 5, 0, 1),
(637, 1, 7, 0, 1),
(638, 1, 8, 0, 1),
(639, 1, 15, 0, 1),
(640, 1, 9, 1, 1),
(641, 1, 10, 0, 1),
(642, 1, 11, 0, 1),
(643, 1, 27, 0, 1),
(644, 1, 25, 0, 1),
(645, 1, 26, 0, 1),
(646, 1, 37, 0, 1),
(647, 1, 23, 0, 1),
(648, 1, 22, 0, 1),
(649, 1, 24, 0, 1),
(650, 1, 33, 0, 1),
(651, 1, 31, 0, 1),
(652, 1, 34, 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `codigo_producto` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `id_categoria` int(11) DEFAULT NULL,
  `descripcion` text CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  `id_tipo_afectacion_igv` int(11) NOT NULL,
  `id_unidad_medida` varchar(3) NOT NULL,
  `costo_unitario` float DEFAULT 0,
  `precio_unitario_con_igv` float DEFAULT 0,
  `precio_unitario_sin_igv` float DEFAULT 0,
  `precio_unitario_mayor_con_igv` float DEFAULT 0,
  `precio_unitario_mayor_sin_igv` float DEFAULT 0,
  `precio_unitario_oferta_con_igv` float DEFAULT 0,
  `precio_unitario_oferta_sin_igv` float DEFAULT NULL,
  `stock` float DEFAULT 0,
  `minimo_stock` float DEFAULT 0,
  `ventas` float DEFAULT 0,
  `costo_total` float DEFAULT 0,
  `imagen` varchar(255) DEFAULT 'no_image.jpg',
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `fecha_actualizacion` date DEFAULT NULL,
  `estado` int(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`codigo_producto`, `id_categoria`, `descripcion`, `id_tipo_afectacion_igv`, `id_unidad_medida`, `costo_unitario`, `precio_unitario_con_igv`, `precio_unitario_sin_igv`, `precio_unitario_mayor_con_igv`, `precio_unitario_mayor_sin_igv`, `precio_unitario_oferta_con_igv`, `precio_unitario_oferta_sin_igv`, `stock`, `minimo_stock`, `ventas`, `costo_total`, `imagen`, `fecha_creacion`, `fecha_actualizacion`, `estado`) VALUES
('7755139002809', 12, 'Paisana extra 5k', 10, 'NIU', 18.29, 22.86, 19.37, 21.95, 18.6, 21.4, 18.13, 21, 11, 0, 384.09, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002810', 11, 'Gloria Fresa 500ml', 10, 'NIU', 3.79, 4.74, 4.01, 4.55, 3.85, 4.43, 3.76, 21, 11, 0, 79.59, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002811', 13, 'Gloria evaporada ligth 400g', 10, 'NIU', 3.4, 4.25, 3.6, 4.08, 3.46, 3.98, 3.37, 25, 15, 0, 85, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002812', 19, 'soda san jorge 40g', 10, 'NIU', 0.5, 0.62, 0.53, 0.6, 0.51, 0.58, 0.5, 28, 18, 0, 14, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002813', 19, 'vainilla field 37g', 10, 'NIU', 0.33, 0.41, 0.35, 0.4, 0.34, 0.39, 0.33, 22, 12, 0, 7.26, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002814', 19, 'Margarita', 10, 'NIU', 0.53, 0.66, 0.56, 0.64, 0.54, 0.62, 0.53, 25, 15, 0, 13.25, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002815', 19, 'soda field 34g', 10, 'NIU', 0.37, 0.46, 0.39, 0.44, 0.38, 0.43, 0.37, 29, 19, 0, 10.73, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002816', 19, 'ritz original', 10, 'NIU', 0.43, 0.54, 0.46, 0.52, 0.44, 0.5, 0.43, 20, 10, 0, 8.6, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002817', 19, 'ritz queso 34g', 10, 'NIU', 0.68, 0.85, 0.72, 0.82, 0.69, 0.8, 0.67, 21, 11, 0, 14.28, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002818', 16, 'Chocobum', 10, 'NIU', 0.62, 0.77, 0.66, 0.74, 0.63, 0.73, 0.61, 24, 14, 0, 14.88, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002819', 19, 'Picaras', 10, 'NIU', 0.6, 0.75, 0.64, 0.72, 0.61, 0.7, 0.59, 28, 18, 0, 16.8, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002820', 19, 'oreo original 36g', 10, 'NIU', 0.57, 0.71, 0.6, 0.68, 0.58, 0.67, 0.57, 21, 11, 0, 11.97, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002821', 19, 'club social 26g', 10, 'NIU', 0.53, 0.66, 0.56, 0.64, 0.54, 0.62, 0.53, 22, 12, 0, 11.66, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002822', 19, 'frac vanilla 45.5g', 10, 'NIU', 0.52, 0.65, 0.55, 0.62, 0.53, 0.61, 0.52, 24, 14, 0, 12.48, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002823', 19, 'frac chocolate 45.5g', 10, 'NIU', 0.52, 0.65, 0.55, 0.62, 0.53, 0.61, 0.52, 20, 10, 0, 10.4, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002824', 19, 'frac chasica 45.5g', 10, 'NIU', 0.52, 0.65, 0.55, 0.62, 0.53, 0.61, 0.52, 23, 13, 0, 11.96, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002825', 16, 'tuyo 22g', 10, 'NIU', 0.5, 0.62, 0.53, 0.6, 0.51, 0.58, 0.5, 25, 15, 0, 12.5, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002826', 19, 'gn rellenitas 36g chocolate', 10, 'NIU', 0.47, 0.59, 0.5, 0.56, 0.48, 0.55, 0.47, 27, 17, 0, 12.69, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002827', 19, 'gn rellenitas 36g coco', 10, 'NIU', 0.47, 0.59, 0.5, 0.56, 0.48, 0.55, 0.47, 24, 14, 0, 11.28, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002828', 19, 'gn rellenitas 36g coco', 10, 'NIU', 0.47, 0.59, 0.5, 0.56, 0.48, 0.55, 0.47, 29, 19, 0, 13.63, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002829', 16, 'cancun', 10, 'NIU', 0.75, 0.94, 0.79, 0.9, 0.76, 0.88, 0.74, 29, 19, 0, 21.75, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002830', 9, 'Big cola 400ml', 10, 'NIU', 1, 1.25, 1.06, 1.2, 1.02, 1.17, 0.99, 20, 10, 0, 20, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002831', 7, 'Zuko Piña', 10, 'NIU', 0.9, 1.12, 0.95, 1.08, 0.92, 1.05, 0.89, 23, 13, 0, 20.7, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002832', 7, 'Zuko Durazno', 10, 'NIU', 0.9, 1.12, 0.95, 1.08, 0.92, 1.05, 0.89, 25, 15, 0, 22.5, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002833', 16, 'chin chin 32g', 10, 'NIU', 0.88, 1.1, 0.93, 1.06, 0.89, 1.03, 0.87, 24, 14, 0, 21.12, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002834', 19, 'Morocha 30g', 10, 'NIU', 0.85, 1.06, 0.9, 1.02, 0.86, 0.99, 0.84, 21, 11, 0, 17.85, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002835', 7, 'Zuko Emoliente', 10, 'NIU', 0.67, 0.84, 0.71, 0.8, 0.68, 0.78, 0.66, 30, 20, 0, 20.1, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002836', 19, 'Choco donuts', 10, 'NIU', 0.56, 0.7, 0.59, 0.67, 0.57, 0.66, 0.56, 22, 12, 0, 12.32, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002837', 9, 'Pepsi 355ml', 10, 'NIU', 1.5, 1.88, 1.59, 1.8, 1.53, 1.75, 1.49, 24, 14, 0, 36, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002838', 4, 'Quaker 120gr', 10, 'NIU', 1.29, 1.61, 1.37, 1.55, 1.31, 1.51, 1.28, 27, 17, 0, 34.83, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002839', 6, 'Pulp Durazno 315ml', 10, 'NIU', 1, 1.25, 1.06, 1.2, 1.02, 1.17, 0.99, 27, 17, 0, 27, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002840', 19, 'morochas wafer 37g', 10, 'NIU', 1, 1.25, 1.06, 1.2, 1.02, 1.17, 0.99, 29, 19, 0, 29, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002841', 16, 'Wafer sublime', 10, 'NIU', 0.92, 1.15, 0.97, 1.1, 0.94, 1.08, 0.91, 26, 16, 0, 23.92, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002842', 19, 'hony bran 33g', 10, 'NIU', 0.9, 1.12, 0.95, 1.08, 0.92, 1.05, 0.89, 29, 19, 0, 26.1, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002843', 16, 'Sublime clásico', 10, 'NIU', 1.06, 1.33, 1.12, 1.27, 1.08, 1.24, 1.05, 23, 13, 0, 24.38, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002844', 11, 'Gloria fresa 180ml', 10, 'NIU', 1.5, 1.88, 1.59, 1.8, 1.53, 1.75, 1.49, 26, 16, 0, 39, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002845', 11, 'Gloria durazno 180ml', 10, 'NIU', 1.5, 1.88, 1.59, 1.8, 1.53, 1.75, 1.49, 21, 11, 0, 31.5, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002846', 11, 'Frutado fresa vasito', 10, 'NIU', 1.39, 1.74, 1.47, 1.67, 1.41, 1.63, 1.38, 22, 12, 0, 30.58, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002847', 11, 'Frutado durazno vasito', 10, 'NIU', 1.39, 1.74, 1.47, 1.67, 1.41, 1.63, 1.38, 30, 20, 0, 41.7, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002848', 4, '3 ositos quinua', 10, 'NIU', 1.9, 2.38, 2.01, 2.28, 1.93, 2.22, 1.88, 25, 15, 0, 47.5, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002849', 9, 'Seven Up 500ml', 10, 'NIU', 1.8, 2.25, 1.91, 2.16, 1.83, 2.11, 1.78, 28, 18, 0, 50.4, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002850', 9, 'Fanta Kola Inglesa 500ml', 10, 'NIU', 1.39, 1.74, 1.47, 1.67, 1.41, 1.63, 1.38, 21, 11, 0, 29.19, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002851', 9, 'Fanta Naranja 500ml', 10, 'NIU', 1.39, 1.74, 1.47, 1.67, 1.41, 1.63, 1.38, 25, 15, 0, 34.75, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002852', 14, 'Noble pq 2 unid', 10, 'NIU', 1.3, 1.62, 1.38, 1.56, 1.32, 1.52, 1.29, 20, 10, 0, 26, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002853', 14, 'Suave pq 2 unid', 10, 'NIU', 1.99, 2.49, 2.11, 2.39, 2.02, 2.33, 1.97, 28, 18, 0, 55.72, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002854', 9, 'Pepsi 750ml', 10, 'NIU', 2.8, 3.5, 2.97, 3.36, 2.85, 3.28, 2.78, 21, 11, 0, 58.8, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002855', 9, 'Coca cola 600ml', 10, 'NIU', 2.6, 3.25, 2.75, 3.12, 2.64, 3.04, 2.58, 22, 12, 0, 57.2, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002856', 9, 'Inca Kola 600ml', 10, 'NIU', 2.6, 3.25, 2.75, 3.12, 2.64, 3.04, 2.58, 24, 14, 0, 62.4, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002857', 14, 'Elite Megarrollo', 10, 'NIU', 2.19, 2.74, 2.32, 2.63, 2.23, 2.56, 2.17, 24, 14, 0, 52.56, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002858', 13, 'Pura vida 395g', 10, 'NIU', 2.6, 3.25, 2.75, 3.12, 2.64, 3.04, 2.58, 23, 13, 0, 59.8, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002859', 13, 'Ideal cremosita 395g', 10, 'NIU', 3, 3.75, 3.18, 3.6, 3.05, 3.51, 2.97, 21, 11, 0, 63, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002860', 13, 'Ideal Light 395g', 10, 'NIU', 2.8, 3.5, 2.97, 3.36, 2.85, 3.28, 2.78, 27, 17, 0, 75.6, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002861', 11, 'Fresa 370ml Laive', 10, 'NIU', 2.19, 2.74, 2.32, 2.63, 2.23, 2.56, 2.17, 28, 18, 0, 61.32, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002862', 13, 'Gloria evaporada entera', 10, 'NIU', 3.2, 4, 3.39, 3.84, 3.25, 3.74, 3.17, 26, 16, 0, 83.2, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002863', 13, 'Laive Ligth caja 480ml', 10, 'NIU', 2.8, 3.5, 2.97, 3.36, 2.85, 3.28, 2.78, 27, 17, 0, 75.6, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002864', 9, 'Pepsi 1.5L', 10, 'NIU', 4.4, 5.5, 4.66, 5.28, 4.47, 5.15, 4.36, 20, 10, 0, 88, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002865', 11, 'Gloria durazno 500ml', 10, 'NIU', 3.79, 4.74, 4.01, 4.55, 3.85, 4.43, 3.76, 23, 13, 0, 87.17, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002866', 11, 'Gloria Vainilla Francesa 500ml', 10, 'NIU', 3.79, 4.74, 4.01, 4.55, 3.85, 4.43, 3.76, 26, 16, 0, 98.54, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002867', 11, 'Griego gloria', 10, 'NIU', 3.65, 4.56, 3.87, 4.38, 3.71, 4.27, 3.62, 24, 14, 0, 87.6, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002868', 9, 'Sabor Oro 1.7L', 10, 'NIU', 3.5, 4.38, 3.71, 4.2, 3.56, 4.09, 3.47, 20, 10, 0, 70, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002869', 3, 'Canchita mantequilla', 10, 'NIU', 3.25, 4.06, 3.44, 3.9, 3.31, 3.8, 3.22, 21, 11, 0, 68.25, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002870', 3, 'Canchita natural', 10, 'NIU', 3.25, 4.06, 3.44, 3.9, 3.31, 3.8, 3.22, 26, 16, 0, 84.5, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002871', 13, 'Laive sin lactosa caja 480ml', 10, 'NIU', 3.17, 3.96, 3.36, 3.8, 3.22, 3.71, 3.14, 27, 17, 0, 85.59, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002872', 12, 'Valle Norte 750g', 10, 'NIU', 3.1, 3.88, 3.28, 3.72, 3.15, 3.63, 3.07, 30, 20, 0, 93, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002873', 11, 'Battimix', 10, 'NIU', 2.89, 3.61, 3.06, 3.47, 2.94, 3.38, 2.87, 25, 15, 0, 72.25, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002874', 3, 'Pringles papas', 10, 'NIU', 2.8, 3.5, 2.97, 3.36, 2.85, 3.28, 2.78, 28, 18, 0, 78.4, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002875', 12, 'Costeño 750g', 10, 'NIU', 3.69, 4.61, 3.91, 4.43, 3.75, 4.32, 3.66, 22, 12, 0, 81.18, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002876', 12, 'Faraon amarillo 1k', 10, 'NIU', 3.39, 4.24, 3.59, 4.07, 3.45, 3.97, 3.36, 21, 11, 0, 71.19, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002877', 15, 'A1 Trozos', 10, 'NIU', 5.17, 6.46, 5.48, 6.2, 5.26, 6.05, 5.13, 30, 20, 0, 155.1, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002878', 14, 'Nova pq 2 unid', 10, 'NIU', 3.99, 4.99, 4.23, 4.79, 4.06, 4.67, 3.96, 25, 15, 0, 99.75, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002879', 14, 'Suave pq 4 unid', 10, 'NIU', 4.58, 5.72, 4.85, 5.5, 4.66, 5.36, 4.54, 28, 18, 0, 128.24, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002880', 15, 'Florida Trozos', 10, 'NIU', 5.15, 6.44, 5.46, 6.18, 5.24, 6.03, 5.11, 23, 13, 0, 118.45, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002881', 14, 'Paracas pq 4 unid', 10, 'NIU', 5, 6.25, 5.3, 6, 5.08, 5.85, 4.96, 22, 12, 0, 110, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002882', 15, 'Trozos de atún Campomar', 10, 'NIU', 4.66, 5.82, 4.94, 5.59, 4.74, 5.45, 4.62, 27, 17, 0, 125.82, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002883', 15, 'A1 Filete', 10, 'NIU', 4.65, 5.81, 4.93, 5.58, 4.73, 5.44, 4.61, 23, 13, 0, 106.95, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002884', 15, 'Real Trozos', 10, 'NIU', 4.63, 5.79, 4.9, 5.56, 4.71, 5.42, 4.59, 21, 11, 0, 97.23, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002885', 11, 'Durazno 1L laive', 10, 'NIU', 5.7, 7.12, 6.04, 6.84, 5.8, 6.67, 5.65, 27, 17, 0, 153.9, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002886', 11, 'Fresa 1L Laive', 10, 'NIU', 5.7, 7.12, 6.04, 6.84, 5.8, 6.67, 5.65, 21, 11, 0, 119.7, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002887', 15, 'A1 Filete Ligth', 10, 'NIU', 6.08, 7.6, 6.44, 7.3, 6.18, 7.11, 6.03, 27, 17, 0, 164.16, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002888', 11, 'Lúcuma 1L Gloria', 10, 'NIU', 5.9, 7.38, 6.25, 7.08, 6, 6.9, 5.85, 22, 12, 0, 129.8, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002889', 11, 'Fresa 1L Gloria', 10, 'NIU', 5.9, 7.38, 6.25, 7.08, 6, 6.9, 5.85, 28, 18, 0, 165.2, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002890', 11, 'Milkito fresa 1L', 10, 'NIU', 5.9, 7.38, 6.25, 7.08, 6, 6.9, 5.85, 24, 14, 0, 141.6, 'no_image.jpg', '2023-10-14 23:57:22', NULL, 1),
('7755139002891', 11, 'Gloria Durazno 1L', 10, 'NIU', 5.9, 7.38, 6.25, 7.08, 6, 6.9, 5.85, 29, 19, 0, 171.1, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002892', 15, 'Filete de atún Campomar', 10, 'NIU', 5.08, 6.35, 5.38, 6.1, 5.17, 5.94, 5.04, 21, 11, 0, 106.68, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002893', 15, 'Florida Filete Ligth', 10, 'NIU', 5.63, 7.04, 5.96, 6.76, 5.73, 6.59, 5.58, 29, 19, 0, 163.27, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002894', 15, 'Filete de atún Florida', 10, 'NIU', 5.4, 6.75, 5.72, 6.48, 5.49, 6.32, 5.35, 23, 13, 0, 124.2, 'no_image.jpg', '2023-10-14 23:57:23', NULL, 1),
('7755139002895', 9, 'Inca Kola 1.5L', 10, 'NIU', 5.9, 7.38, 6.25, 7.08, 6, 6.9, 5.85, 43, 19, 0, 253.7, 'no_image.jpg', '2023-10-15 03:09:22', NULL, 1),
('7755139002896', 9, 'Coca Cola 1.5L', 10, 'NIU', 5.9, 7.38, 6.25, 7.08, 6, 6.9, 5.85, 40, 17, 0, 236, 'no_image.jpg', '2023-10-15 03:09:22', NULL, 1),
('7755139002897', 5, 'Red Bull 250ml', 10, 'NIU', 5.33, 6.66, 5.65, 6.4, 5.42, 6.24, 5.28, 40, 12, 0, 213.2, 'no_image.jpg', '2023-10-15 03:09:22', NULL, 1),
('7755139002898', 9, 'Sprite 3L', 10, 'NIU', 7.49, 9.36, 7.93, 8.99, 7.62, 8.76, 7.43, 50, 17, 0, 374.5, 'no_image.jpg', '2023-10-15 03:15:03', NULL, 1),
('7755139002899', 9, 'Pepsi 3L', 10, 'NIU', 8, 10, 8.47, 9.6, 8.14, 9.36, 7.93, 47, 16, 0, 376, 'no_image.jpg', '2023-10-15 03:15:03', NULL, 1),
('7755139002900', 13, 'Laive 200gr', 10, 'NIU', 8.9, 11.12, 9.43, 10.68, 9.05, 10.41, 8.82, 49, 11, 0, 436.1, 'no_image.jpg', '2023-10-15 03:15:03', NULL, 1),
('7755139002901', 8, 'Gloria Pote con sal', 10, 'NIU', 10, 11.49, 9.74, 11.03, 9.35, 10.75, 9.11, 51, 16, 0, 510, 'no_image.jpg', '2023-10-15 03:15:03', NULL, 1),
('7755139002902', 10, 'Deleite 1L', 10, 'NIU', 9.8, 12.25, 10.38, 11.76, 9.97, 11.47, 9.72, 62, 19, 0, 607.6, 'no_image.jpg', '2023-10-15 03:15:03', NULL, 1),
('7755139002903', 10, 'Sao 1L', 10, 'NIU', 12.1, 15.12, 12.82, 14.52, 12.31, 14.16, 12, 41, 13, 0, 496.1, 'no_image.jpg', '2023-10-15 03:15:03', NULL, 1),
('7755139002904', 10, 'Cocinero 1L', 10, 'NIU', 13.05, 15.5, 13.14, 14.88, 12.61, 14.51, 12.29, 45, 19, 24, 587.25, 'no_image.jpg', '2023-10-15 03:15:03', NULL, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `id` int(11) NOT NULL,
  `id_tipo_documento` varchar(45) NOT NULL,
  `ruc` varchar(45) NOT NULL,
  `razon_social` varchar(150) NOT NULL,
  `direccion` varchar(255) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `proveedores`
--

INSERT INTO `proveedores` (`id`, `id_tipo_documento`, `ruc`, `razon_social`, `direccion`, `telefono`, `estado`) VALUES
(1, '6', '20604915351', 'MEN GRAPH S.A.C.	', 'CALLE FANING 7878', '956231245', 1),
(2, '6', '20538856674', 'ARTROSCOPICTRAUMA S.A.C.	', 'CALLE LIMA 123456', '987542154', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `serie`
--

CREATE TABLE `serie` (
  `id` int(11) NOT NULL,
  `id_tipo_comprobante` varchar(3) NOT NULL,
  `serie` varchar(4) NOT NULL,
  `correlativo` int(11) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `serie`
--

INSERT INTO `serie` (`id`, `id_tipo_comprobante`, `serie`, `correlativo`, `estado`) VALUES
(1, '03', 'B001', 175, 1),
(2, '01', 'F001', 28, 1),
(3, '03', 'B002', 1, 1),
(4, '03', 'B003', 15, 1),
(5, '03 ', 'B002', 15, 1),
(6, '01', 'FL01', 2, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_afectacion_igv`
--

CREATE TABLE `tipo_afectacion_igv` (
  `id` int(11) NOT NULL,
  `codigo` char(3) NOT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `letra_tributo` varchar(45) DEFAULT NULL,
  `codigo_tributo` varchar(45) DEFAULT NULL,
  `nombre_tributo` varchar(45) DEFAULT NULL,
  `tipo_tributo` varchar(45) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_afectacion_igv`
--

INSERT INTO `tipo_afectacion_igv` (`id`, `codigo`, `descripcion`, `letra_tributo`, `codigo_tributo`, `nombre_tributo`, `tipo_tributo`, `estado`) VALUES
(1, '10', 'GRAVADO - OPERACIÓN ONEROSA', 'S', '1000', 'IGV', 'VAT', 1),
(2, '20', 'EXONERADO - OPERACIÓN ONEROSA', 'E', '9997', 'EXO', 'VAT', 1),
(3, '30', 'INAFECTO - OPERACIÓN ONEROSA', 'O', '9998', 'INA', 'FRE', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_comprobante`
--

CREATE TABLE `tipo_comprobante` (
  `id` int(11) NOT NULL,
  `codigo` varchar(3) NOT NULL,
  `descripcion` varchar(50) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `tipo_comprobante`
--

INSERT INTO `tipo_comprobante` (`id`, `codigo`, `descripcion`, `estado`) VALUES
(1, '01', 'FACTURA', 1),
(2, '03', 'BOLETA', 1),
(3, '07', 'NOTA DE CRÉDITO', 1),
(4, '08', 'NOTA DE DÉBITO', 1),
(5, '09', 'GUIA DE REMISIÓN', 1),
(6, 'RA', 'RESUMEN ANULACIONES', 1),
(7, 'RC', 'RESUMEN COMPROBANTES', 1),
(8, 'XX', 'PRUEBA', 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_documento`
--

CREATE TABLE `tipo_documento` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(45) NOT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_documento`
--

INSERT INTO `tipo_documento` (`id`, `descripcion`, `estado`) VALUES
(0, 'DOC.TRIB.NO.DOM.SIN.RUC', 1),
(1, 'DNI', 1),
(4, 'CARNET DE EXTRANJERIA', 1),
(6, 'RUC', 1),
(7, 'PASAPORTE', 1),
(10, 'PRUEBA 2', 0),
(11, 'PRUEBA 3', 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_movimiento_caja`
--

CREATE TABLE `tipo_movimiento_caja` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(150) DEFAULT NULL,
  `estado` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_movimiento_caja`
--

INSERT INTO `tipo_movimiento_caja` (`id`, `descripcion`, `estado`) VALUES
(1, 'DEVOLUCIÓN', 1),
(2, 'GASTO', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_operacion`
--

CREATE TABLE `tipo_operacion` (
  `codigo` varchar(4) NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `estado` tinyint(4) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_operacion`
--

INSERT INTO `tipo_operacion` (`codigo`, `descripcion`, `estado`) VALUES
('0101', 'Venta interna', 1),
('0102', 'Venta Interna – Anticipos', 1),
('0103', 'Venta interna - Itinerante', 1),
('0110', 'Venta Interna - Sustenta Traslado de Mercadería - Remitente', 1),
('0111', 'Venta Interna - Sustenta Traslado de Mercadería - Transportista', 1),
('0112', 'Venta Interna - Sustenta Gastos Deducibles Persona Natural', 1),
('0120', 'Venta Interna - Sujeta al IVAP', 1),
('0200', 'Exportación de Bienes ', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_precio_venta_unitario`
--

CREATE TABLE `tipo_precio_venta_unitario` (
  `codigo` varchar(2) NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipo_precio_venta_unitario`
--

INSERT INTO `tipo_precio_venta_unitario` (`codigo`, `descripcion`, `estado`) VALUES
('01', 'Precio unitario (incluye el IGV)', 1),
('02', 'Valor referencial unitario en operaciones no onerosas', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `nombre_usuario` varchar(100) DEFAULT NULL,
  `apellido_usuario` varchar(100) DEFAULT NULL,
  `usuario` varchar(100) DEFAULT NULL,
  `clave` text DEFAULT NULL,
  `id_perfil_usuario` int(11) DEFAULT NULL,
  `id_caja` int(11) DEFAULT NULL,
  `estado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `nombre_usuario`, `apellido_usuario`, `usuario`, `clave`, `id_perfil_usuario`, `id_caja`, `estado`) VALUES
(1, 'TUTORIALES', 'PHPERU', 'tperu', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 1, 1, 1),
(2, 'PAOLO', 'GUERRERO', 'pguerrero', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 2, 1, 1),
(3, 'FIORELLA JESSICA', 'OSORES VALLEJO', 'fosoresv29', '123456', 2, 2, 1),
(4, 'RAFAEL', 'LOZANO', 'rlozano', '123456', 2, 1, 1),
(5, 'ANDY', 'POLO', 'apolo', 'asdsad', 2, 2, 1),
(6, 'ALEX', 'VALERA', 'avalera123', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 1, 2, 1),
(7, 'ALDO', 'CORZO', 'acorzo123', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 1, 2, 1),
(8, 'RENATO', 'TAPIA', 'prueba4', '$2a$07$azybxcags23425sdg23sdeV5s.14AcWhL0szWBmqFbPuIRMEC.9eu', 2, 2, 1),
(9, 'EMILIA', 'LOZANO OSORES', 'elozano', '$2a$07$azybxcags23425sdg23sdeanQZqjaf6Birm2NvcYTNtJw24CsO5uq', 1, 2, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta`
--

CREATE TABLE `venta` (
  `id` int(11) NOT NULL,
  `id_empresa_emisora` int(11) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `id_serie` int(11) NOT NULL,
  `serie` varchar(4) NOT NULL,
  `correlativo` int(11) NOT NULL,
  `fecha_emision` date NOT NULL,
  `hora_emision` varchar(10) DEFAULT NULL,
  `fecha_vencimiento` date NOT NULL,
  `id_moneda` varchar(3) NOT NULL,
  `forma_pago` varchar(45) NOT NULL,
  `total_operaciones_gravadas` float DEFAULT 0,
  `total_operaciones_exoneradas` float DEFAULT 0,
  `total_operaciones_inafectas` float DEFAULT 0,
  `total_igv` float DEFAULT 0,
  `importe_total` float DEFAULT 0,
  `nombre_xml` varchar(255) DEFAULT NULL,
  `xml_base64` text DEFAULT NULL,
  `xml_cdr_sunat_base64` text DEFAULT NULL,
  `codigo_error_sunat` int(11) DEFAULT NULL,
  `mensaje_respuesta_sunat` text DEFAULT NULL,
  `hash_signature` varchar(45) DEFAULT NULL,
  `estado_respuesta_sunat` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `venta`
--

INSERT INTO `venta` (`id`, `id_empresa_emisora`, `id_cliente`, `id_serie`, `serie`, `correlativo`, `fecha_emision`, `hora_emision`, `fecha_vencimiento`, `id_moneda`, `forma_pago`, `total_operaciones_gravadas`, `total_operaciones_exoneradas`, `total_operaciones_inafectas`, `total_igv`, `importe_total`, `nombre_xml`, `xml_base64`, `xml_cdr_sunat_base64`, `codigo_error_sunat`, `mensaje_respuesta_sunat`, `hash_signature`, `estado_respuesta_sunat`) VALUES
(1, 1, 10, 1, 'B001', 175, '2023-10-14', '07:10:38', '2023-10-14', 'PEN', 'Contado', 315.36, 0, 0, 56.7648, 372.125, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `arqueo_caja`
--
ALTER TABLE `arqueo_caja`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `cajas`
--
ALTER TABLE `cajas`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `codigo_unidad_medida`
--
ALTER TABLE `codigo_unidad_medida`
  ADD UNIQUE KEY `id_UNIQUE` (`id`);

--
-- Indices de la tabla `compras`
--
ALTER TABLE `compras`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_cod_producto_idx` (`codigo_producto`),
  ADD KEY `fk_id_compra_idx` (`id_compra`);

--
-- Indices de la tabla `detalle_venta`
--
ALTER TABLE `detalle_venta`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `empresas`
--
ALTER TABLE `empresas`
  ADD PRIMARY KEY (`id_empresa`);

--
-- Indices de la tabla `forma_pago`
--
ALTER TABLE `forma_pago`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `impuestos`
--
ALTER TABLE `impuestos`
  ADD PRIMARY KEY (`id_tipo_operacion`);

--
-- Indices de la tabla `kardex`
--
ALTER TABLE `kardex`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_id_producto_idx` (`codigo_producto`);

--
-- Indices de la tabla `modulos`
--
ALTER TABLE `modulos`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `moneda`
--
ALTER TABLE `moneda`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `movimientos_arqueo_caja`
--
ALTER TABLE `movimientos_arqueo_caja`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `perfiles`
--
ALTER TABLE `perfiles`
  ADD PRIMARY KEY (`id_perfil`);

--
-- Indices de la tabla `perfil_modulo`
--
ALTER TABLE `perfil_modulo`
  ADD PRIMARY KEY (`idperfil_modulo`),
  ADD KEY `id_perfil` (`id_perfil`),
  ADD KEY `id_modulo` (`id_modulo`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`codigo_producto`),
  ADD UNIQUE KEY `codigo_producto_UNIQUE` (`codigo_producto`),
  ADD KEY `fk_id_categoria_idx` (`id_categoria`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `serie`
--
ALTER TABLE `serie`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tipo_afectacion_igv`
--
ALTER TABLE `tipo_afectacion_igv`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tipo_comprobante`
--
ALTER TABLE `tipo_comprobante`
  ADD PRIMARY KEY (`id`,`codigo`);

--
-- Indices de la tabla `tipo_documento`
--
ALTER TABLE `tipo_documento`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tipo_movimiento_caja`
--
ALTER TABLE `tipo_movimiento_caja`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tipo_operacion`
--
ALTER TABLE `tipo_operacion`
  ADD PRIMARY KEY (`codigo`);

--
-- Indices de la tabla `tipo_precio_venta_unitario`
--
ALTER TABLE `tipo_precio_venta_unitario`
  ADD PRIMARY KEY (`codigo`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD KEY `id_perfil_usuario` (`id_perfil_usuario`),
  ADD KEY `fk_id_caja_idx` (`id_caja`);

--
-- Indices de la tabla `venta`
--
ALTER TABLE `venta`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `arqueo_caja`
--
ALTER TABLE `arqueo_caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `cajas`
--
ALTER TABLE `cajas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla `compras`
--
ALTER TABLE `compras`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT de la tabla `detalle_venta`
--
ALTER TABLE `detalle_venta`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `empresas`
--
ALTER TABLE `empresas`
  MODIFY `id_empresa` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `forma_pago`
--
ALTER TABLE `forma_pago`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `kardex`
--
ALTER TABLE `kardex`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=131;

--
-- AUTO_INCREMENT de la tabla `modulos`
--
ALTER TABLE `modulos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT de la tabla `movimientos_arqueo_caja`
--
ALTER TABLE `movimientos_arqueo_caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `perfiles`
--
ALTER TABLE `perfiles`
  MODIFY `id_perfil` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `perfil_modulo`
--
ALTER TABLE `perfil_modulo`
  MODIFY `idperfil_modulo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=653;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `serie`
--
ALTER TABLE `serie`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `tipo_afectacion_igv`
--
ALTER TABLE `tipo_afectacion_igv`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `tipo_comprobante`
--
ALTER TABLE `tipo_comprobante`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `tipo_movimiento_caja`
--
ALTER TABLE `tipo_movimiento_caja`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `venta`
--
ALTER TABLE `venta`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD CONSTRAINT `fk_cod_producto` FOREIGN KEY (`codigo_producto`) REFERENCES `productos` (`codigo_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_id_compra` FOREIGN KEY (`id_compra`) REFERENCES `compras` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `kardex`
--
ALTER TABLE `kardex`
  ADD CONSTRAINT `fk_cod_producto_kardex` FOREIGN KEY (`codigo_producto`) REFERENCES `productos` (`codigo_producto`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `perfil_modulo`
--
ALTER TABLE `perfil_modulo`
  ADD CONSTRAINT `id_modulo` FOREIGN KEY (`id_modulo`) REFERENCES `modulos` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `id_perfil` FOREIGN KEY (`id_perfil`) REFERENCES `perfiles` (`id_perfil`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `fk_id_categoria` FOREIGN KEY (`id_categoria`) REFERENCES `categorias` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `fk_id_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`id_perfil_usuario`) REFERENCES `perfiles` (`id_perfil`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
