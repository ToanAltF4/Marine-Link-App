package com.marinelink.cart;

import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ResourceNotFoundException;
import com.marinelink.products.PriceTier;
import com.marinelink.products.PriceTierResponse;
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
import java.util.Comparator;
import java.util.ArrayList;
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

    @Transactional(readOnly = true)
    public CartResponse getActiveCart(UUID userPublicId) {
        return cartRepository.findActiveByUserPublicId(userPublicId)
                .map(this::toResponse)
                .orElseGet(() -> new CartResponse(
                        null,
                        true,
                        List.of(),
                        0,
                        0,
                        BigDecimal.ZERO));
    }

    @Transactional
    public CartResponse syncCart(UUID userPublicId, CartSyncRequest request) {
        Cart cart = getOrCreateCart(userPublicId);

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

    @Transactional
    public CartResponse addItem(UUID userPublicId, CartItemCreateRequest request) {
        Cart cart = getOrCreateCart(userPublicId);
        Product product = getProduct(request.productId());
        int currentQuantity = findItem(cart, request.productId())
                .map(CartItem::getQuantity)
                .orElse(0);
        int nextQuantity = currentQuantity + request.quantity();
        validateItem(product, nextQuantity);

        CartItem item = findItem(cart, request.productId())
                .orElseGet(() -> {
                    CartItem created = CartItem.builder()
                            .publicId(UUID.randomUUID())
                            .cart(cart)
                            .product(product)
                            .build();
                    cart.getItems().add(created);
                    return created;
                });
        item.setQuantity(nextQuantity);
        item.setSelected(request.selected() == null || request.selected());
        item.setPriceTier(resolvePriceTier(product, nextQuantity));

        return toResponse(cartRepository.save(cart));
    }

    @Transactional
    public CartResponse updateItem(UUID userPublicId, UUID productPublicId, CartItemUpdateRequest request) {
        if (request.quantity() == null && request.selected() == null) {
            throw new BusinessException("Can cap nhat so luong hoac trang thai chon", HttpStatus.UNPROCESSABLE_ENTITY);
        }
        Cart cart = getActiveCartOrThrow(userPublicId);
        CartItem item = findItem(cart, productPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay san pham trong gio hang"));
        Product product = item.getProduct();

        if (request.quantity() != null) {
            validateItem(product, request.quantity());
            item.setQuantity(request.quantity());
            item.setPriceTier(resolvePriceTier(product, request.quantity()));
        }
        if (request.selected() != null) {
            item.setSelected(request.selected());
        }

        return toResponse(cartRepository.save(cart));
    }

    @Transactional
    public CartResponse removeItem(UUID userPublicId, UUID productPublicId) {
        Cart cart = getActiveCartOrThrow(userPublicId);
        CartItem item = findItem(cart, productPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay san pham trong gio hang"));
        cart.getItems().remove(item);
        return toResponse(cartRepository.save(cart));
    }

    @Transactional
    public CartResponse clearItems(UUID userPublicId) {
        Cart cart = cartRepository.findActiveByUserPublicId(userPublicId)
                .orElseGet(() -> getOrCreateCart(userPublicId));
        cart.getItems().clear();
        return toResponse(cartRepository.save(cart));
    }

    private Cart getOrCreateCart(UUID userPublicId) {
        User user = userRepository.findActiveByPublicId(userPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay nguoi dung"));
        return cartRepository.findActiveByUserPublicId(userPublicId)
                .orElseGet(() -> Cart.builder()
                        .publicId(UUID.randomUUID())
                        .user(user)
                        .build());
    }

    private Cart getActiveCartOrThrow(UUID userPublicId) {
        return cartRepository.findActiveByUserPublicId(userPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay gio hang"));
    }

    private Product getProduct(UUID productPublicId) {
        return productRepository.findDetailByPublicId(productPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay san pham"));
    }

    private java.util.Optional<CartItem> findItem(Cart cart, UUID productPublicId) {
        return cart.getItems()
                .stream()
                .filter(item -> item.getProduct().getPublicId().equals(productPublicId))
                .findFirst();
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
        List<MergedCartItem> mergedItems = mergedItems(cart.getItems());
        List<CartItemResponse> items = mergedItems
                .stream()
                .map(item -> new CartItemResponse(
                        item.product().getPublicId(),
                        item.product().getName(),
                        item.product().getImageUrl(),
                        item.product().getUnit(),
                        item.quantity(),
                        item.selected(),
                        item.priceTier() != null ? item.priceTier().getPublicId() : null,
                        item.product().getBasePrice(),
                        unitPrice(item.product(), item.priceTier()),
                        unitPrice(item.product(), item.priceTier()).multiply(BigDecimal.valueOf(item.quantity())),
                        item.product().getMinOrderQuantity(),
                        item.product().getStockQuantity(),
                        item.product().getPriceTiers()
                                .stream()
                                .sorted(Comparator.comparingInt(PriceTier::getMinQuantity))
                                .map(PriceTierResponse::from)
                                .toList()))
                .toList();
        int totalItemCount = mergedItems
                .stream()
                .mapToInt(MergedCartItem::quantity)
                .sum();
        int totalSelectedItemCount = mergedItems
                .stream()
                .filter(MergedCartItem::selected)
                .mapToInt(MergedCartItem::quantity)
                .sum();
        BigDecimal subtotalAmount = mergedItems
                .stream()
                .filter(MergedCartItem::selected)
                .map(item -> unitPrice(item.product(), item.priceTier()).multiply(BigDecimal.valueOf(item.quantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new CartResponse(
                cart.getPublicId(),
                cart.getItems().isEmpty(),
                items,
                totalItemCount,
                totalSelectedItemCount,
                subtotalAmount);
    }

    private List<MergedCartItem> mergedItems(List<CartItem> items) {
        Map<UUID, MergedCartItem> merged = new LinkedHashMap<>();
        for (CartItem item : items) {
            Product product = item.getProduct();
            MergedCartItem existing = merged.get(product.getPublicId());
            int quantity = item.getQuantity();
            boolean selected = item.isSelected();
            if (existing != null) {
                quantity += existing.quantity();
                selected = selected || existing.selected();
            }
            PriceTier tier = resolvePriceTier(product, quantity);
            merged.put(
                    product.getPublicId(),
                    new MergedCartItem(product, tier, quantity, selected));
        }
        return new ArrayList<>(merged.values());
    }

    private BigDecimal unitPrice(Product product, PriceTier tier) {
        return tier != null ? tier.getUnitPrice() : product.getBasePrice();
    }

    private record MergedCartItem(Product product, PriceTier priceTier, int quantity, boolean selected) {
    }
}
