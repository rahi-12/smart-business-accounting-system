const MAX_MINOR_UNITS = 999999999999n;

function invalidInput(message) {
    const error = new Error(message);
    error.code = "INVALID_INPUT";
    return error;
}

function decimalToScaledInteger(value, field, scale, maximum, allowZero = true) {
    const text = typeof value === "number" ? String(value) : value;
    const pattern = scale === 0 ? /^\d+$/ : new RegExp(`^\\d+(?:\\.\\d{1,${scale}})?$`);
    if (typeof text !== "string") {
        throw invalidInput(`${field} must be a non-negative number with at most ${scale} decimal places.`);
    }
    if (text.length > 20) {
        throw invalidInput(`${field} is outside the supported numeric range.`);
    }
    if (!pattern.test(text)) {
        throw invalidInput(`${field} must be a non-negative number with at most ${scale} decimal places.`);
    }

    const [whole, fraction = ""] = text.split(".");
    const factor = 10n ** BigInt(scale);
    const scaled = BigInt(whole) * factor + BigInt((fraction + "0".repeat(scale)).slice(0, scale) || "0");
    if ((!allowZero && scaled === 0n) || scaled > maximum) {
        throw invalidInput(`${field} is outside the supported numeric range.`);
    }
    return scaled;
}

function formatScaledInteger(value, scale) {
    const factor = 10n ** BigInt(scale);
    const whole = value / factor;
    const fraction = String(value % factor).padStart(scale, "0");
    return scale === 0 ? String(whole) : `${whole}.${fraction}`;
}

function parseMoney(value, field, allowZero = true) {
    return decimalToScaledInteger(value, field, 2, MAX_MINOR_UNITS, allowZero);
}

function validateCalculationOptions(options = {}) {
    const discountType = options.discount_type === undefined ? "fixed" : options.discount_type;
    if (!["percent", "fixed"].includes(discountType)) {
        throw invalidInput("discount_type must be percent or fixed.");
    }
    const discountValue = options.discount_value === undefined
        ? 0n
        : decimalToScaledInteger(
            options.discount_value,
            "discount_value",
            2,
            discountType === "percent" ? 10000n : MAX_MINOR_UNITS
        );
    const taxRate = options.tax_rate === undefined
        ? 0n
        : decimalToScaledInteger(options.tax_rate, "tax_rate", 2, 10000n);
    return {
        discountType,
        discountValue,
        taxRate,
    };
}

function roundHalfUp(numerator, denominator) {
    return (numerator + denominator / 2n) / denominator;
}

function calculateInvoice(items, options = {}) {
    if (!Array.isArray(items) || items.length < 1 || items.length > 100) {
        throw invalidInput("items must contain between 1 and 100 items.");
    }

    const normalizedItems = [];
    let subtotal = 0n;
    for (const [index, item] of items.entries()) {
        const quantity = decimalToScaledInteger(
            item.quantity,
            `items[${index}].quantity`,
            2,
            MAX_MINOR_UNITS,
            false
        );
        const unitPrice = parseMoney(item.unit_price, `items[${index}].unit_price`);
        const lineTotal = roundHalfUp(quantity * unitPrice, 100n);
        if (lineTotal > MAX_MINOR_UNITS) {
            throw invalidInput("Calculated line total exceeds NUMERIC(12,2).");
        }
        subtotal += lineTotal;
        if (subtotal > MAX_MINOR_UNITS) {
            throw invalidInput("Calculated subtotal exceeds NUMERIC(12,2).");
        }
        normalizedItems.push({
            description: item.description,
            quantity: formatScaledInteger(quantity, 2),
            unit_price: formatScaledInteger(unitPrice, 2),
            line_total: formatScaledInteger(lineTotal, 2),
        });
    }

    const { discountType, discountValue, taxRate } = validateCalculationOptions(options);
    const discount = discountType === "percent"
        ? roundHalfUp(subtotal * discountValue, 10000n)
        : discountValue;
    if (discount > subtotal) {
        throw invalidInput("A fixed discount cannot exceed the subtotal.");
    }

    const taxable = subtotal - discount;
    const tax = roundHalfUp(taxable * taxRate, 10000n);
    const total = taxable + tax;
    if (tax > MAX_MINOR_UNITS || total > MAX_MINOR_UNITS) {
        throw invalidInput("Calculated invoice total exceeds NUMERIC(12,2).");
    }

    return {
        items: normalizedItems,
        subtotal: formatScaledInteger(subtotal, 2),
        discount_type: discountType,
        discount_value: formatScaledInteger(discountValue, 2),
        discount: formatScaledInteger(discount, 2),
        tax_rate: formatScaledInteger(taxRate, 2),
        tax: formatScaledInteger(tax, 2),
        total_amount: formatScaledInteger(total, 2),
    };
}

module.exports = {
    calculateInvoice,
    validateCalculationOptions,
    MAX_MINOR_UNITS,
};
