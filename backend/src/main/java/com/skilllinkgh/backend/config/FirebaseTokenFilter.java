package com.skilllinkgh.backend.config;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * Validates the Firebase ID token sent in the Authorization header.
 * Sets the authenticated user's UID into the Spring Security context.
 */
public class FirebaseTokenFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {

        String header = request.getHeader("Authorization");

        if (header != null && header.startsWith("Bearer ")) {
            String idToken = header.substring(7);
            try {
                FirebaseToken decoded = FirebaseAuth.getInstance().verifyIdToken(idToken);
                String uid = decoded.getUid();

                // Determine role from custom claims (set by Firebase Cloud Functions)
                String role = "ROLE_USER";
                Object roleClaim = decoded.getClaims().get("role");
                if ("artisan".equals(roleClaim)) role = "ROLE_ARTISAN";
                if ("admin".equals(roleClaim))   role = "ROLE_ADMIN";

                UsernamePasswordAuthenticationToken auth =
                    new UsernamePasswordAuthenticationToken(uid, null, List.of(new SimpleGrantedAuthority(role)));

                SecurityContextHolder.getContext().setAuthentication(auth);
            } catch (Exception e) {
                // Invalid token — clear context and let Spring Security reject it
                SecurityContextHolder.clearContext();
            }
        }

        chain.doFilter(request, response);
    }
}
