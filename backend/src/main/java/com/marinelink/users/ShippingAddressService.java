package com.marinelink.users;

import com.marinelink.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ShippingAddressService {

    private final ShippingAddressRepository shippingAddressRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<ShippingAddressResponse> listForUser(UUID userPublicId) {
        return shippingAddressRepository.findActiveByUserPublicId(userPublicId)
                .stream()
                .map(ShippingAddressResponse::from)
                .toList();
    }

    @Transactional
    public ShippingAddressResponse createForUser(UUID userPublicId, ShippingAddressRequest request) {
        User user = userRepository.findActiveByPublicId(userPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay nguoi dung"));
        boolean shouldBeDefault = request.isDefault()
                || shippingAddressRepository.countActiveByUserId(user.getId()) == 0;

        if (shouldBeDefault) {
            shippingAddressRepository.clearDefaultForUser(user.getId());
        }

        ShippingAddress address = ShippingAddress.builder()
                .publicId(UUID.randomUUID())
                .user(user)
                .label(trimToNull(request.label()))
                .receiverName(request.receiverName().trim())
                .receiverPhone(request.receiverPhone().trim())
                .addressLine(request.addressLine().trim())
                .defaultAddress(shouldBeDefault)
                .build();

        return ShippingAddressResponse.from(shippingAddressRepository.save(address));
    }

    @Transactional
    public ShippingAddressResponse updateForUser(
            UUID userPublicId,
            UUID addressPublicId,
            ShippingAddressRequest request) {
        ShippingAddress address = shippingAddressRepository
                .findActiveByPublicIdAndUserPublicId(addressPublicId, userPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay dia chi giao hang"));

        if (request.isDefault()) {
            shippingAddressRepository.clearDefaultForUserExcept(address.getUser().getId(), address.getId());
            address.setDefaultAddress(true);
        } else if (shippingAddressRepository.countActiveByUserId(address.getUser().getId()) > 1) {
            address.setDefaultAddress(false);
        }

        address.setLabel(trimToNull(request.label()));
        address.setReceiverName(request.receiverName().trim());
        address.setReceiverPhone(request.receiverPhone().trim());
        address.setAddressLine(request.addressLine().trim());

        return ShippingAddressResponse.from(shippingAddressRepository.save(address));
    }

    @Transactional
    public void deleteForUser(UUID userPublicId, UUID addressPublicId) {
        ShippingAddress address = shippingAddressRepository
                .findActiveByPublicIdAndUserPublicId(addressPublicId, userPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay dia chi giao hang"));

        boolean wasDefault = address.isDefaultAddress();
        address.setDeletedAt(Instant.now());
        address.setDefaultAddress(false);
        shippingAddressRepository.save(address);

        if (wasDefault) {
            shippingAddressRepository
                    .findFirstByUser_IdAndDeletedAtIsNullOrderByUpdatedAtDesc(address.getUser().getId())
                    .ifPresent(nextDefault -> {
                        nextDefault.setDefaultAddress(true);
                        shippingAddressRepository.save(nextDefault);
                    });
        }
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
