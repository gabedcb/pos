<?php

require_once "conexion.php";

class VentasModelo
{

    public $resultado;


    static public function mdlObtenerMoneda()
    {
        $stmt = Conexion::conectar()->prepare("select id,concat(id, ' - ', descripcion) as descripcion  from moneda where estado = 1;");
        $stmt->execute();
        return $stmt->fetchAll();
    }

    static public function mdlObtenerDatosEmpresa($id_empresa)
    {
        $stmt = Conexion::conectar()->prepare("SELECT id_empresa, 
                                                        razon_social, 
                                                        nombre_comercial, 
                                                        id_tipo_documento as tipo_documento, 
                                                        ruc, 
                                                        direccion, 
                                                        simbolo_moneda, 
                                                        email, 
                                                        telefono, 
                                                        provincia, 
                                                        departamento, 
                                                        distrito, 
                                                        ubigeo, 
                                                        usuario_sol, 
                                                        clave_sol
                                                FROM empresas
                                                where id_empresa = :id_empresa");
        $stmt->bindParam(":id_empresa", $id_empresa, PDO::PARAM_STR);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_NAMED);
    }
}
