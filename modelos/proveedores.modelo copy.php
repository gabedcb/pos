<?php

require_once "conexion.php";

class ProveedoresModelo
{


    static public function mdlObtenerProveedores($post)
    {

        $column = ["id", "tipo_documento", "ruc", "razon_social", "direccion", "telefono", "estado"];

        $query = " SELECT '' as detalles,
                            '' as opciones,
                            p.id, 
                            td.descripcion as tipo_documento, 
                            p.ruc, 
                            p.razon_social, 
                            p.direccion, 
                            p.telefono,
                            case when p.estado = 1 then 'ACTIVO' else 'INACTIVO' end as estado
                        FROM proveedores p inner join tipo_documento td on p.id_tipo_documento = td.id";

        if (isset($post["search"]["value"])) {
            $query .= ' WHERE p.razon_social like "%' . $post["search"]["value"] . '%"
                        or p.direccion like "%' . $post["search"]["value"] . '%"
                        or p.ruc like "%' . $post["search"]["value"] . '%"
                        or p.direccion like "%' . $post["search"]["value"] . '%"
                        or case when p.estado = 1 then "ACTIVO" else "INACTIVO" end like "%' . $post["search"]["value"] . '%"';
        }

        if (isset($post["order"])) {
            $query .= ' ORDER BY ' . $column[$post['order']['0']['column']] . ' ' . $post['order']['0']['dir'] . ' ';
        } else {
            $query .= ' ORDER BY id asc ';
        }

        //SE AGREGA PAGINACION
        if ($post["length"] != -1) {
            $query1 = " LIMIT " . $post["start"] . ", " . $post["length"];
        }

        $stmt = Conexion::conectar()->prepare($query);

        $stmt->execute();

        $number_filter_row = $stmt->rowCount();

        $stmt =  Conexion::conectar()->prepare($query . $query1);

        $stmt->execute();

        $results = $stmt->fetchAll(PDO::FETCH_NAMED);

        $data = array();

        foreach ($results as $row) {
            $sub_array = array();
            $sub_array[] = $row['detalles'];
            $sub_array[] = $row['opciones'];
            $sub_array[] = $row['id'];
            $sub_array[] = $row['tipo_documento'];
            $sub_array[] = $row['ruc'];
            $sub_array[] = $row['razon_social'];
            $sub_array[] = $row['direccion'];
            $sub_array[] = $row['telefono'];
            $sub_array[] = $row['estado'];
            $data[] = $sub_array;
        }

        $stmt = Conexion::conectar()->prepare(" SELECT '' as detalles,
                                                    '' as opciones,
                                                    p.id, 
                                                    td.descripcion as tipo_documento, 
                                                    p.ruc, 
                                                    p.razon_social, 
                                                    p.direccion, 
                                                    p.telefono,
                                                    case when p.estado = 1 then 'ACTIVO' else 'INACTIVO' end as estado
                                            FROM proveedores p inner join tipo_documento td on p.id_tipo_documento = td.id");

        $stmt->execute();

        $count_all_data = $stmt->rowCount();

        $output = array(
            'draw' => $post['draw'],
            "recordsTotal" => $count_all_data,
            "recordsFiltered" => $number_filter_row,
            "data" => $data
        );

        return $output;
    }
}
