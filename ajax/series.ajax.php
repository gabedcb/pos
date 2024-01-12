<?php

require_once "../modelos/series.modelo.php";

//=========================================================================================
// PETICIONES POST
//=========================================================================================
if (isset($_POST["accion"])) {

    switch ($_POST["accion"]) {

        case 'obtener_tipo_comprobante':

            $response = SeriesModelo::mdlObtenerTipoComprobante();
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;
    }
}
