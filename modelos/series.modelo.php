<?php

require_once "conexion.php";

class SeriesModelo
{

    static public function mdlObtenerTipoComprobante()
    {
        $stmt = Conexion::conectar()->prepare("select codigo,descripcion
                                            from tipo_comprobante where estado = 1 ");
        $stmt->execute();
        return $stmt->fetchAll();
    }

}
