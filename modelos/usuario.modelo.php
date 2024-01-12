<?php

require_once "conexion.php";

class UsuarioModelo
{

    static public function mdlIniciarSesion($usuario, $password)
    {

        try {

            $stmt = Conexion::conectar()->prepare("select *
                                                from usuarios u 
                                                inner join perfiles p
                                                on u.id_perfil_usuario = p.id_perfil
                                                inner join perfil_modulo pm
                                                on pm.id_perfil = u.id_perfil_usuario
                                                inner join modulos m
                                                on m.id = pm.id_modulo
                                                where u.usuario = :usuario
                                                and u.clave = :password
                                                and vista_inicio = 1");

            $stmt->bindParam(":usuario", $usuario, PDO::PARAM_STR);
            $stmt->bindParam(":password", $password, PDO::PARAM_STR);

            $stmt->execute();

            $respuesta = $stmt->fetchAll(PDO::FETCH_CLASS);

            // var_dump(count($respuesta));

            if (count($respuesta) > 0) {

                $_SESSION["usuario"] = $respuesta[0];

                $respuesta["tipo_msj"] = "success";
                $respuesta["msj"] = "Usuario autenticado";
            } else {

                $respuesta["tipo_msj"] = "error";
                $respuesta["msj"] = "El usuario y/o contraseña son invalidos";
            }
        } catch (Exception $e) {
            $respuesta["tipo_msj"] = "error";
            $respuesta["msj"] = "El usuario y/o contraseña son invalidos";
        }


        return $respuesta;
    }

    static public function mdlObtenerMenuUsuario($id_usuario)
    {

        $stmt = Conexion::conectar()->prepare("SELECT m.id,m.modulo,m.icon_menu,m.vista,pm.vista_inicio,
                                                    (select count(1) from modulos m1
                                                            where m1.padre_id = m.id
                                                            and exists (select 'x' from perfil_modulo pm1 
                                                                        where pm1.id_modulo = m1.id 
                                                                        and pm1.vista_inicio = 1
                                                                        AND pm1.id_perfil = u.id_perfil_usuario)) as abrir_arbol
                                                from usuarios u inner join perfiles p on u.id_perfil_usuario = p.id_perfil
                                                inner join perfil_modulo pm on pm.id_perfil = p.id_perfil
                                                inner join modulos m on m.id = pm.id_modulo
                                                where u.id_usuario = :id_usuario
                                                and (m.padre_id is null or m.padre_id = 0)
                                                order by m.orden");

        $stmt->bindParam(":id_usuario", $id_usuario, PDO::PARAM_STR);

        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_CLASS);
    }

    static public function mdlObtenerSubMenuUsuario($idMenu, $id_usuario)
    {

        $stmt = Conexion::conectar()->prepare("SELECT m.id,m.modulo,m.icon_menu,m.vista,pm.vista_inicio
                                                from usuarios u inner join perfiles p on u.id_perfil_usuario = p.id_perfil
                                                inner join perfil_modulo pm on pm.id_perfil = p.id_perfil
                                                inner join modulos m on m.id = pm.id_modulo
                                                where u.id_usuario = :id_usuario
                                                and m.padre_id = :idMenu
                                                order by m.orden");

        $stmt->bindParam(":idMenu", $idMenu, PDO::PARAM_STR);
        $stmt->bindParam(":id_usuario", $id_usuario, PDO::PARAM_STR);

        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_CLASS);
    }

}
