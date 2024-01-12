

<?php

require_once "../modelos/proveedores.modelo.php";

//=========================================================================================
// PETICIONES POST
//=========================================================================================
if (isset($_POST["accion"])) {

    switch ($_POST["accion"]) {

        case 'obtener_proveedores':

            $response = ProveedoresModelo::mdlObtenerProveedores($_POST);
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            break;
        }
}
