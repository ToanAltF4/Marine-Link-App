package com.marinelink.config;

import com.marinelink.common.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.util.List;

/**
 * STOMP-over-WebSocket for realtime chat (ML-63).
 *
 * <ul>
 *   <li>Handshake endpoint: {@code /ws} (raw WebSocket).</li>
 *   <li>Simple in-memory broker on {@code /topic}; clients subscribe to
 *       {@code /topic/chat.{roomId}} and the server broadcasts new messages there.</li>
 *   <li>Auth: the JWT is validated on the STOMP CONNECT frame (Authorization
 *       header) and bound as the session user; unauthenticated connects are rejected.</li>
 * </ul>
 */
@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").setAllowedOriginPatterns("*");
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic");
        registry.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new ChannelInterceptor() {
            @Override
            public Message<?> preSend(Message<?> message, MessageChannel channel) {
                StompHeaderAccessor accessor =
                        MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
                if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
                    String token = extractToken(accessor);
                    if (token == null || !jwtTokenProvider.validateToken(token)) {
                        throw new IllegalArgumentException(
                                "Thiếu hoặc sai token cho kết nối WebSocket");
                    }
                    List<String> roles = jwtTokenProvider.getRoles(token);
                    List<GrantedAuthority> authorities = roles == null
                            ? List.of()
                            : roles.stream()
                                    .<GrantedAuthority>map(r -> new SimpleGrantedAuthority("ROLE_" + r))
                                    .toList();
                    accessor.setUser(new UsernamePasswordAuthenticationToken(
                            jwtTokenProvider.getSubject(token), null, authorities));
                }
                return message;
            }
        });
    }

    private String extractToken(StompHeaderAccessor accessor) {
        String bearer = accessor.getFirstNativeHeader("Authorization");
        if (bearer != null && bearer.startsWith("Bearer ")) {
            return bearer.substring(7);
        }
        return accessor.getFirstNativeHeader("token");
    }
}
