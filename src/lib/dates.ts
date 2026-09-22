const ISO_DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;
export function isValidIsoDate(value: string): boolean {
 const m=ISO_DATE_RE.exec(value); if(!m)return false;
 const y=Number(m[1]),mo=Number(m[2]),d=Number(m[3]),date=new Date(Date.UTC(y,mo-1,d));
 return date.getUTCFullYear()===y&&date.getUTCMonth()===mo-1&&date.getUTCDate()===d;
}
export function todayIsoDate(): string {
 const parts=new Intl.DateTimeFormat("en-CA",{timeZone:"Europe/Paris",year:"numeric",month:"2-digit",day:"2-digit"}).formatToParts(new Date());
 const v=Object.fromEntries(parts.map(p=>[p.type,p.value])); return `${v.year}-${v.month}-${v.day}`;
}
export function daysBetweenIsoDates(from:string,to:string):number{
 if(!isValidIsoDate(from)||!isValidIsoDate(to))throw new Error("invalid_iso_date");
 const utc=(v:string)=>{const [y,m,d]=v.split("-").map(Number);return Date.UTC(y,m-1,d);};
 return Math.round((utc(to)-utc(from))/86400000);
}
