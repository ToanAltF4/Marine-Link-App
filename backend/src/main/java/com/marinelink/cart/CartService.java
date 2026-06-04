package com.marinelink.cart;

import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ResourceNotFoundException;
import com.marinelink.products.PriceTier;
import com.marinelink.products.Product;
import com.marinelink.products.ProductRepository;
import com.marinelink.products.ProductStatus;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CartService {

    private final CartRepository cartRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;

    @Transactional
    public CartResponse syncCart(UUID userPublicId, CartSyncRequest request) {
        User user = userRepository.findActiveByPublicId(userPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay nguoi dung"));
        Cart cart = cartRepository.findActiveByUserPublicId(userPublicId)
                .orElseGet(() -> Cart.builder()
                        .publicId(UUID.randomUUID())
                        .user(user)
                        .build());

        cart.getItems().clear();
        for (CartSyncItemRequest itemRequest : uniqueItems(request.items()).values()) {
            Product product = productRepository.findDetailByPublicId(itemRequest.productId())
                    .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay san pham"));
            validateItem(product, itemRequest.quantity());
            PriceTier tier = resolvePriceTier(product, itemRequest.quantity());
            cart.getItems().add(CartItem.builder()
                    .publicId(UUID.randomUUID())
                    .cart(cart)
                    .product(product)
                    .priceTier(tier)
                    .quantity(itemRequest.quantity())
                    .selected(itemRequest.selected())
                    .build());
        }

        return toResponse(cartRepository.save(cart));
    }

    private Map<UUID, CartSyncItemRequest> uniqueItems(List<CartSyncItemRequest> items) {
        Map<UUID, CartSyncItemRequest> unique = new LinkedHashMap<>();
        if (items == null) {
            return unique;
        }
        for (CartSyncItemRequest item : items) {
            unique.put(item.productId(), item);
        }
        return unique;
    }

    private void validateItem(Product product, int quantity) {
        if (product.getStatus() == ProductStatus.DISABLED
                || product.getStatus() == ProductStatus.OUT_OF_STOCK) {
            throw new BusinessException("San pham khong kha dung", HttpStatus.UNPROCESSABLE_ENTITY);
        }
        if (quantity < product.getMinOrderQuantity()) {
            throw new BusinessException("So luong dat hang duoi muc toi thieu", HttpStatus.UNPROCESSABLE_ENTITY);
        }
        if (quantity > product.getStockQuantity()) {
            throw new BusinessException("San pham khong du ton kho", HttpStatus.UNPROCESSABLE_ENTITY);
        }
    }

    private PriceTier resolvePriceTier(Product product, int quantity) {
        return product.getPriceTiers()
                .stream()
                .filter(tier -> matches(tier, quantity))
                .findFirst()
                .orElse(null);
    }

    private boolean matches(PriceTier tier, int quantity) {
        return quantity >= tier.getMinQuantity()
                && (tier.getMaxQuantity() == null || quantity <= tier.getMaxQuantity());
    }

    private CartResponse toResponse(Cart cart) {
        List<CartItemResponse> items = cart.getItems()
                .stream()
                .map(item -> CartItemResponse.from(item, unitPrice(item)))
                .toList();
        int totalItemCount = cart.getItems()
                .stream()
                .mapToInt(CartItem::getQuantity)
                .sum();
        int totalSelectedItemCount = cart.getItems()
                .stream()
                .filter(CartItem::isSelected)
                .mapToInt(CartItem::getQuantity)
                .sum();
        BigDecimal subtotalAmount = cart.getItems()
                .stream()
                .filter(CartItem::isSelected)
                .map(item -> unitPrice(item).multiply(BigDecimal.valueOf(item.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new CartResponse(
                cart.getPublicId(),
                cart.getItems().isEmpty(),
                items,
                totalItemCount,
                totalSelectedItemCount,
                subtotalAmount);
    }

    private BigDecimal unitPrice(CartItem item) {
        return item.getPriceTier() != null
                ? item.getPriceTier().getUnitPrice()
                : item.getProduct().getBasePrice();
    }
}
