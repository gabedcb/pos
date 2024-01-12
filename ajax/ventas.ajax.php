<?php

require_once "../modelos/ventas.modelo.php";
require_once "../modelos/productos.modelo.php";
require_once "apis/api_facturacion.php";



/* ===================================================================================  */
/* P O S T   P E T I C I O N E S  */
/* ===================================================================================  */
if (isset($_POST["accion"])) {

    switch ($_POST["accion"]) {


        case 'obtener_moneda':

            $response = VentasModelo::mdlObtenerMoneda();

            echo json_encode($response, JSON_UNESCAPED_UNICODE);

            break;

       
    }
}
