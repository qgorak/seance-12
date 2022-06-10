<?php

namespace services\DAO;

use models\Basket;
use models\Order;
use models\Orderdetail;
use Ubiquity\orm\DAO;

class OrderDetailsDAOLoader {

	public function get($id): ?Object {
		return DAO::getById(Order::class,$id,['orderdetails.product.section']);
	}

    public function getBasket($id): ?Object {
        return DAO::getById(Basket::class,$id,['basketdetails.product']);
    }

    public function getDetails($id): ?Object {
        return DAO::getById(OrderDetail::class,$id);
    }

    public function getAll(): ?array {
        return DAO::getAll(Order::class,"",['orderdetails.product']);
    }


}
