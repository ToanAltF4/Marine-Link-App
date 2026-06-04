package com.marinelink.orders;

import com.marinelink.cart.Cart;
import com.marinelink.cart.CartItem;
import com.marinelink.cart.CartItemRepository;
import com.marinelink.cart.CartRepository;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ResourceNotFoundException;
import com.marinelink.products.PriceTier;
import com.marinelink.products.Product;
import com.marinelink.products.ProductRepository;
import com.marinelink.products.ProductStatus;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OrderService {

    private static final Map<OrderStatus, List<OrderStatus>> ALLOWED_TRANSITIONS =
            new EnumMap<>(OrderStatus.class);

    static {
        ALLOWED_TRANSITIONS.put(OrderStatus.PENDING, List.of(OrderStatus.CONFIRMED, OrderStatus.CANCELLED));
        ALLOWED_TRANSITIONS.put(OrderStatus.CONFIRMED, List.of(OrderStatus.SHIPPING, OrderStatus.CANCELLED));
        ALLOWED_TRANSITIONS.put(OrderStatus.SHIPPING, List.of(OrderStatus.COMPLETED));
        ALLOWED_TRANSITIONS.put(OrderStatus.COMPLETED, List.of());
        ALLOWED_TRANSITIONS.put(OrderStatus.CANCELLED, List.of());
    }

    private final OrderRepository orderRepository;
    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;

    @Transactional
    public OrderSummaryResponse createFromActiveCart(UUID userPublicId, OrderCreateRequest request) {
        User user = userRepository.findActiveByPublicId(userPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay nguoi dung"));
        OrderSource orderSource = resolveOrderSource(userPublicId, request);

        Order order = Order.builder()
                .publicId(UUID.randomUUID())
                .orderCode(nextOrderCode())
                .user(user)
                .status(OrderStatus.PENDING)
                .paymentMethod(request.paymentMethod())
                .paymentStatus(PaymentStatus.UNPAID)
                .receiverName(request.receiverName().trim())
                .receiverPhone(request.receiverPhone().trim())
                .shippingAddress(request.shippingAddress().trim())
                .note(trimToNull(request.note()))
                .shippingFee(BigDecimal.ZERO)
                .discountAmount(BigDecimal.ZERO)
                .build();

        BigDecimal subtotal = BigDecimal.ZERO;
        for (OrderLine line : orderSource.lines()) {
            Product product = line.product();
            validateItem(product, line.quantity());

            BigDecimal unitPrice = resolveUnitPrice(product, line.priceTier(), line.quantity());
            BigDecimal lineTotal = unitPrice.multiply(BigDecimal.valueOf(line.quantity()));
            OrderItem orderItem = OrderItem.builder()
                    .publicId(UUID.randomUUID())
                    .order(order)
                    .product(product)
                    .productNameSnapshot(product.getName())
                    .productUnitSnapshot(product.getUnit())
                    .unitPrice(unitPrice)
                    .quantity(line.quantity())
                    .lineTotal(lineTotal)
                    .build();
            order.getItems().add(orderItem);
            subtotal = subtotal.add(lineTotal);
        }

        order.setSubtotalAmount(subtotal);
        order.setTotalAmount(subtotal.add(order.getShippingFee()).subtract(order.getDiscountAmount()));
        order.getStatusHistory().add(OrderStatusHistory.builder()
                .publicId(UUID.randomUUID())
                .order(order)
                .fromStatus(null)
                .toStatus(OrderStatus.PENDING)
                .changedBy(user)
                .note("Order created")
                .build());

        Order saved = orderRepository.save(order);
        if (orderSource.cartIdToClear() != null) {
            cartItemRepository.deleteSelectedByCartId(orderSource.cartIdToClear());
        }
        return OrderSummaryResponse.from(saved);
    }

    private OrderSource resolveOrderSource(UUID userPublicId, OrderCreateRequest request) {
        if (request.items() != null && !request.items().isEmpty()) {
            return new OrderSource(linesFromRequest(request.items()), null);
        }

        Cart cart = cartRepository.findActiveByUserPublicId(userPublicId)
                .orElseThrow(() -> new BusinessException("Gio hang dang trong", HttpStatus.UNPROCESSABLE_ENTITY));
        List<OrderLine> lines = cart.getItems()
                .stream()
                .filter(CartItem::isSelected)
                .map(item -> new OrderLine(
                        item.getProduct(),
                        item.getPriceTier(),
                        item.getQuantity()))
                .toList();
        if (lines.isEmpty()) {
            throw new BusinessException("Gio hang dang trong", HttpStatus.UNPROCESSABLE_ENTITY);
        }
        return new OrderSource(lines, cart.getId());
    }

    private List<OrderLine> linesFromRequest(List<OrderCreateItemRequest> items) {
        Map<UUID, OrderCreateItemRequest> uniqueItems = new LinkedHashMap<>();
        for (OrderCreateItemRequest item : items) {
            uniqueItems.put(item.productId(), item);
        }
        return uniqueItems.values()
                .stream()
                .map(item -> {
                    Product product = productRepository.findDetailByPublicId(item.productId())
                            .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay san pham"));
                    return new OrderLine(
                            product,
                            resolvePriceTier(product, item.quantity()),
                            item.quantity());
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public Page<OrderListItemResponse> listOrders(
            UUID userPublicId,
            boolean canViewAll,
            int page,
            int size,
            OrderStatus status,
            String fromDate,
            String toDate) {
        Pageable pageable = PageRequest.of(
                Math.max(page, 0),
                Math.max(1, Math.min(size, 100)),
                Sort.by(Sort.Order.desc("createdAt")));
        Instant from = parseDateStart(fromDate);
        Instant to = parseDateEnd(toDate);

        Specification<Order> specification = (root, ignoredQuery, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (!canViewAll) {
                predicates.add(cb.equal(root.get("user").get("publicId"), userPublicId));
            }
            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            if (from != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), from));
            }
            if (to != null) {
                predicates.add(cb.lessThan(root.get("createdAt"), to));
            }
            return cb.and(predicates.toArray(Predicate[]::new));
        };

        return orderRepository.findAll(specification, pageable)
                .map(OrderListItemResponse::from);
    }

    @Transactional(readOnly = true)
    public OrderDetailResponse getOrderDetail(UUID userPublicId, boolean canViewAll, UUID orderPublicId) {
        Order order = orderRepository.findDetailByPublicId(orderPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay don hang"));
        if (!canViewAll && !order.getUser().getPublicId().equals(userPublicId)) {
            throw new ResourceNotFoundException("Khong tim thay don hang");
        }
        return OrderDetailResponse.from(order);
    }

    @Transactional
    public OrderStatusUpdateResponse updateStatus(
            UUID changedByPublicId,
            UUID orderPublicId,
            OrderStatus targetStatus,
            String note) {
        User changedBy = userRepository.findActiveByPublicId(changedByPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay nguoi dung"));
        Order order = orderRepository.findDetailByPublicId(orderPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay don hang"));
        OrderStatus currentStatus = order.getStatus();
        if (!ALLOWED_TRANSITIONS.getOrDefault(currentStatus, List.of()).contains(targetStatus)) {
            throw new BusinessException("Khong the chuyen trang thai don hang", HttpStatus.UNPROCESSABLE_ENTITY);
        }

        order.setStatus(targetStatus);
        Instant now = Instant.now();
        switch (targetStatus) {
            case CONFIRMED -> order.setConfirmedAt(now);
            case SHIPPING -> order.setShippedAt(now);
            case COMPLETED -> order.setCompletedAt(now);
            case CANCELLED -> order.setCancelledAt(now);
            default -> {
            }
        }
        order.getStatusHistory().add(OrderStatusHistory.builder()
                .publicId(UUID.randomUUID())
                .order(order)
                .fromStatus(currentStatus)
                .toStatus(targetStatus)
                .changedBy(changedBy)
                .note(trimToNull(note))
                .build());
        return OrderStatusUpdateResponse.from(orderRepository.save(order));
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

    private BigDecimal resolveUnitPrice(Product product, PriceTier selectedTier, int quantity) {
        if (selectedTier != null && matches(selectedTier, quantity)) {
            return selectedTier.getUnitPrice();
        }
        return product.getPriceTiers()
                .stream()
                .filter(tier -> matches(tier, quantity))
                .map(PriceTier::getUnitPrice)
                .findFirst()
                .orElse(product.getBasePrice());
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

    private String nextOrderCode() {
        Instant now = Instant.now();
        LocalDate today = LocalDate.ofInstant(now, ZoneOffset.UTC);
        Instant start = today.atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant end = today.plusDays(1).atStartOfDay().toInstant(ZoneOffset.UTC);
        long sequence = orderRepository.countByCreatedAtBetween(start, end) + 1;
        return "ML-%s-%04d".formatted(today.toString().replace("-", ""), sequence);
    }

    private Instant parseDateStart(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(value.trim()).atStartOfDay().toInstant(ZoneOffset.UTC);
        } catch (DateTimeParseException ex) {
            return Instant.parse(value.trim());
        }
    }

    private Instant parseDateEnd(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(value.trim()).plusDays(1).atStartOfDay().toInstant(ZoneOffset.UTC);
        } catch (DateTimeParseException ex) {
            return Instant.parse(value.trim());
        }
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private record OrderSource(List<OrderLine> lines, Long cartIdToClear) {
    }

    private record OrderLine(Product product, PriceTier priceTier, int quantity) {
    }
}
